Components.utils.import('resource://gre/modules/Services.jsm')
Components.utils.import('resource://gre/modules/AddonManager.jsm')

require('Formatter.js')
require('bbt-common.coffee')

Zotero.BetterBibTeX = {}

Zotero.BetterBibTeX.log = (msg...) ->
  msg = for m in msg
    switch
      when (typeof m) in ['string', 'number'] then '' + m
      when m instanceof Error and m.name then "#{m.name}: #{m.message} \n(#{m.fileName}, #{m.lineNumber})\n#{m.stack}"
      when m instanceof Error then "#{e}\n#{e.stack}"
      else JSON.stringify(m)

  Zotero.debug("[better-bibtex] #{msg.join(' ')}")
  return

Zotero.BetterBibTeX.pref = {}

Zotero.BetterBibTeX.pref.prefs = Components.classes['@mozilla.org/preferences-service;1'].getService(Components.interfaces.nsIPrefService).getBranch('extensions.zotero.translators.better-bibtex.')

Zotero.BetterBibTeX.pref.observer = {
  register: -> Zotero.BetterBibTeX.pref.prefs.addObserver('', this, false)
  unregister: -> Zotero.BetterBibTeX.pref.prefs.removeObserver('', this)
  observe: (subject, topic, data) ->
    if data == 'citeKeyFormat'
      Zotero.BetterBibTeX.DB.query('delete from keys where citeKeyFormat is not null and citeKeyFormat <> ?', [Zotero.BetterBibTeX.pref.get('citeKeyFormat')])
    return
}

Zotero.BetterBibTeX.pref.ZoteroObserver = {
  register: -> Zotero.Prefs.prefBranch.addObserver('', this, false)
  unregister: -> Zotero.Prefs.prefBranch.removeObserver('', this)
  observe: (subject, topic, data) ->
    if data == 'recursiveCollections'
      # trigger all auto exports
    return
}

Zotero.BetterBibTeX.pref.snapshot = ->
  stash = Object.create(null)
  for key in @prefs.getChildList('')
    stash[key] = @get(key)
  return stash

Zotero.BetterBibTeX.pref.stash = -> @stashed = @snapshot()

Zotero.BetterBibTeX.pref.restore = ->
  for own key, value of @stashed ? {}
    @set(key, value)
  return

Zotero.BetterBibTeX.pref.set = (key, value) ->
  return Zotero.Prefs.set("translators.better-bibtex.#{key}", value)

Zotero.BetterBibTeX.pref.get = (key) ->
  return Zotero.Prefs.get("translators.better-bibtex.#{key}")

Zotero.BetterBibTeX.formatter = (pattern) ->
  @formatters ?= Object.create(null)
  @formatters[pattern] = BetterBibTeXFormatter.parse(pattern) unless @formatters[pattern]
  return @formatters[pattern]

Zotero.BetterBibTeX.init = ->
  @log("Running init: #{@initialized}")
  return if @initialized
  @initialized = true

  # re-schedule all auto exports that were not generated under @auto.recursive

  @translators = Object.create(null)
  @threadManager = Components.classes['@mozilla.org/thread-manager;1'].getService()
  @windowMediator = Components.classes['@mozilla.org/appshell/window-mediator;1'].getService(Components.interfaces.nsIWindowMediator)
  @DB = new Zotero.DBConnection('betterbibtex')

  @findKeysSQL = "select coalesce(i.libraryID, 0) as libraryID, i.itemID as itemID, idv.value as extra
                  from items i
                  join itemData id on i.itemID = id.itemID
                  join itemDataValues idv on idv.valueID = id.valueID
                  join fields f on id.fieldID = f.fieldID
                  where f.fieldName = 'extra' and not i.itemID in (select itemID from deletedItems)
                    and (idv.value like '%bibtex:%' or idv.value like '%biblatexcitekey[%')"

  @DB.query('create table if not exists _version_ (tablename primary key, version not null, unique (tablename, version))')
  @DB.query("insert or ignore into _version_ (tablename, version) values ('keys', 0)")

  version = @DB.valueQuery("select version from _version_ where tablename = 'keys'")
  if version == 0
    @DB.query('create table keys (itemID primary key, libraryID not null, citekey not null, pinned)')
    @DB.query("insert or replace into _version_ (tablename, version) values ('keys', 1)")

  if version <= 2
    @pref.set('scan-citekeys', true)
    @DB.query("insert or replace into _version_ (tablename, version) values ('keys', 3)")

  if version <= 3
    @DB.query('alter table keys rename to keys2')
    @DB.query('create table keys (itemID primary key, libraryID not null, citekey not null, citeKeyFormat)')
    @DB.query('insert into keys (itemID, libraryID, citekey, citeKeyFormat)
               select itemID, libraryID, citekey, case when pinned = 1 then null else ? end from keys2', [@pref.get('citeKeyFormat')])
    @DB.query("insert or replace into _version_ (tablename, version) values ('keys', 4)")

  if version <= 4
    @DB.query("
      create table cache (
        itemid not null,
        context not null,
        citekey not null,
        entry not null,
        primary key (itemid, context))
      ")
    @DB.query("insert or replace into _version_ (tablename, version) values ('keys', 5)")

  @DB.query('delete from keys where citeKeyFormat is not null and citeKeyFormat <> ?', [@pref.get('citeKeyFormat')])

  Zotero.Translate.Export::Sandbox.BetterBibTeX = {
    __exposedProps__: {cache: 'r', keymanager: 'r'}
    keymanager: @keymanager.init()
    cache: @cache.init()
  }

  @pref.observer.register()

  for endpoint in @endpoints
    url = "/better-bibtex/#{endpoint}"
    ep = Zotero.Server.Endpoints[url] = ->
    ep.prototype = @endpoints[endpoint]

  if @pref.get('scan-citekeys')
    for row in Zotero.DB.query(@findKeysSQL) or []
      @DB.query('insert or replace into keys (itemID, libraryID, citekey, citeKeyFormat) values (?, ?, ?, null)', [ row.itemID, row.libraryID, @keymanager.extract({extra: row.extra}) ])
    @pref.set('scan-citekeys', false)

  @loadTranslators()

  # monkey-patch Zotero.ItemTreeView.prototype.getCellText to replace the 'extra' column with the citekey
  # I wish I didn't have to hijack the extra field, but Zotero has checks in numerous places to make sure it only
  # displays 'genuine' Zotero fields, and monkey-patching around all of those got to be way too invasive (and this
  # fragile)
  Zotero.ItemTreeView.prototype.getCellText = ((original) ->
    return (row, column) ->
      if column.id == 'zotero-items-column-extra' && Zotero.BetterBibTeX.pref.get('show-citekey')
        item = this._getItemAtRow(row)
        if !(item?.ref) || item.ref.isAttachment() || item.ref.isNote()
          return ''
        else
          key = Zotero.BetterBibTeX.keymanager.get({itemID: item.id, libraryID: item.libraryID}, {metadata: true})
          return key.citekey + (if key.citeKeyFormat then ' *' else '')

      return original.apply(this, arguments)
    )(Zotero.ItemTreeView.prototype.getCellText)

  # monkey-patch Zotero.Translate.Base.prototype.translate to capture export data
  Zotero.Translate.Base.prototype.translate = ((original) ->
    return (libraryID, saveAttachments) ->
      if this.translator?[0] && this.type == 'export' && this.path && this._displayOptions?['Keep updated']
        # I don't want 'Keep updated' to be remembered as a default
        try
          settings = JSON.parse(Zotero.Prefs.get('export.translatorSettings'))
          if settings['Keep updated']
            delete settings['Keep updated']
            Zotero.Prefs.set('export.translatorSettings', JSON.stringify(settings));
        catch

        # data to define new auto-export
        config = {
          target: this.path
          collection: this._collection?._id
          context: BBTContext( { translator: this.translator[0].translatorID, options: this._displayOptions, preferences: Zotero.BetterBibTeX.pref.snapshot() } )
          recursive: Zotero.BetterBibTeX.auto.recursive()
        }

      return original.apply(this, arguments)
    )(Zotero.Translate.Base.prototype.translate)

  notifierID = Zotero.Notifier.registerObserver(@itemChanged, ['item'])
  window.addEventListener('unload', ((e) -> Zotero.Notifier.unregisterObserver(notifierID)), false)

  uninstaller = {
    onUninstalling: (addon, needsRestart) ->
      return unless addon.id == 'better-bibtex@iris-advies.com'
      Zotero.BetterBibTeX.removeTranslators()
      return

    onOperationCancelled: (addon, needsRestart) ->
      return unless addon.id == 'better-bibtex@iris-advies.com'
      if !(addon.pendingOperations & AddonManager.PENDING_UNINSTALL)
        Zotero.BetterBibTeX.loadTranslators()
      return
  }
  AddonManager.addAddonListener(uninstaller)

  return

Zotero.BetterBibTeX.loadTranslators = ->
  @safeLoad('Better BibTeX.js')
  @safeLoad('Better BibLaTeX.js')
  @safeLoad('LaTeX Citation.js')
  @safeLoad('Pandoc Citation.js')
  @safeLoad('Zotero TestCase.js')
  Zotero.Translators.init()
  return

Zotero.BetterBibTeX.removeTranslators = ->
  for own name, header of @translators
    fileName = Zotero.Translators.getFileNameFromLabel(header.label, header.translatorID)
    destFile = Zotero.getTranslatorsDirectory()
    destFile.append(fileName)
    destFile.remove(false)
  Zotero.Translators.init()
  return

Zotero.BetterBibTeX.itemChanged = {}

Zotero.BetterBibTeX.itemChanged.notify = (event, type, ids, extraData) ->
  switch event
    when 'delete'
      for key in extraData
        v = extraData[key]
        i = {itemID: key}
        Zotero.BetterBibTeX.clearKey(i, true)
      if extraData.length > 0
        Zotero.BetterBibTeX.DB.query("delete from cache where itemid in (#{('' + id for id in extraData).join(',')})")

    when 'add', 'modify', 'trash'
      break if ids.length is 0

      ids = '(' + ('' + id for id in ids).join(',') + ')'

      Zotero.BetterBibTeX.DB.query("delete from cache where itemid in #{ids}")
      Zotero.BetterBibTeX.DB.query("delete from keys where itemID in #{ids}")

      if event != 'trash'
        for item in Zotero.DB.query("#{Zotero.BetterBibTeX.findKeysSQL} and i.itemID in #{ids}") or []
          citekey = Zotero.BetterBibTeX.keymanager.extract({extra: item.extra})
          if Zotero.BetterBibTeX.pref.get('key-conflict-policy') == 'change'
            Zotero.BetterBibTeX.DB.query('delete from keys where libraryID = ? and citeKeyFormat is not null and citekey = ?', [item.libraryID, citekey])
            Zotero.BetterBibTeX.DB.query('delete from cache where citekey = ?', [citekey])
          Zotero.BetterBibTeX.DB.query('insert or replace into keys (itemID, libraryID, citekey, citeKeyFormat) values (?, ?, ?, null)', [ item.itemID, item.libraryID, citekey ])

        for item in Zotero.DB.query("select coalesce(libraryID, 0) as libraryID, itemID from items where itemID in #{ids}") or []
          Zotero.BetterBibTeX.keymanager.get(item, 'on-change')

Zotero.BetterBibTeX.clearKey = (item, onlyCache) ->
  if not onlyCache
    _item = {extra: '' + item.getField('extra')}
    citekey = not @keymanager.extract(_item)
    if citekey
      item.setField('extra', _item.extra)
      item.save()
  @DB.query('delete from keys where itemID = ?', [item.itemID])
  return

Zotero.BetterBibTeX.displayOptions = (url) ->
  params = {}
  hasParams = false
  for key in [ 'exportCharset', 'exportNotes?', 'useJournalAbbreviation?' ]
    try
      isBool = key.match(/[?]$/)
      key = key.replace(isBool[0], '') if isBool
      params[key] = url.query[key]
      params[key] = [ 'y', 'yes', 'true' ].indexOf(params[key].toLowerCase()) >= 0 if isBool
      hasParams = true
    catch
  return params if hasParams
  return null

Zotero.BetterBibTeX.translate = (translator, items, displayOptions) ->
  throw 'null translator' unless translator

  translation = new Zotero.Translate.Export
  translation.setItems(items) if items
  translation.setTranslator(translator)
  translation.setDisplayOptions(displayOptions)

  status = {finished: false}

  translation.setHandler('done', (obj, success) ->
    status.success = success
    status.finished = true
    status.data = obj.string if success
    return)
  translation.translate()

  while not status.finished # ugly spinlock
    continue

  return status.data if status.success
  throw 'export failed'

Zotero.BetterBibTeX.safeLoad = (translator) ->
  try
    @load(translator)
  catch err
    @log("Loading #{translator} failed", err)

Zotero.BetterBibTeX.load = (translator) ->
  header = null
  data = null
  start = -1
  try
    data = Zotero.File.getContentsFromURL("resource://zotero-better-bibtex/translators/#{translator}")
    start = data.indexOf('{') if data
    if start >= 0
      len = data.indexOf('}', start)
      if len > 0
        len -= start
        while len < 3000
          try
            header = JSON.parse(data.substring(start, len).trim())
            data = data.substring(start + len, data.length)
            break
          catch
          len++
  catch err
    header = null

  if not header
    @log("Loading #{translator} failed: could not parse header")
    return

  @translators[header.label.toLowerCase().replace(/[^a-z]/, '')] = header
  Zotero.Translators.save(header, data)
  return

Zotero.BetterBibTeX.getTranslator = (name) ->
  name = name.toLowerCase().replace(/[^a-z]/, '')
  translator = @translators[name]
  translator ?= @translators["better#{name}"]
  translator ?= @translators["zotero#{name}"]
  throw "No translator #{name}; available: #{Object.keys(@translators).join(', ')}" unless translator
  return translator.translatorID

Zotero.BetterBibTeX.clearCiteKeys = (onlyCache) ->
  win = @windowMediator.getMostRecentWindow('navigator:browser')
  items = Zotero.Items.get((item.id for item in win.ZoteroPane.getSelectedItems() when !item.isAttachment() && !item.isNote()))
  for item in items
    @clearKey(item, onlyCache)
  return items

Zotero.BetterBibTeX.pinCiteKeys = ->
  for item in @clearCiteKeys(true)
    @keymanager.get(item, 'manual')

Zotero.BetterBibTeX.safeGetAll = ->
  try
    all = Zotero.Items.getAll()
    all = [all] if all and not Array.isArray(all)
  catch err
    all = false
  if not all then all = []
  return all

Zotero.BetterBibTeX.safeGet = (ids) ->
  return [] if ids.length is 0
  all = Zotero.Items.get(ids)
  if not all then return []
  return all

Zotero.BetterBibTeX.allowAutoPin = -> Zotero.Prefs.get('sync.autoSync') or not Zotero.Sync.Server.enabled

Zotero.BetterBibTeX.toArray = (item) ->
  item = Zotero.Items.get(item.itemID) if not item.setField and not item.itemType and item.itemID
  item = item.toArray() if item.setField # TODO: switch to serialize when Zotero does
  throw 'format: no item\n' + (new Error('dummy')).stack if not item.itemType
  return item

require('preferences.coffee')
require('keymanager.coffee')
require('web-endpoints.coffee')
require('debug-bridge.coffee')
require('cache.coffee')

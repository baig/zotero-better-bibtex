Zotero.BetterBibTeX.pref.serverURL = (extension) ->
  collectionsView = Zotero.getActiveZoteroPane()?.collectionsView
  itemGroup = collectionsView?._getItemAtRow(collectionsView.selection?.currentIndex)
  return unless itemGroup

  try
    serverPort = Zotero.Prefs.get('httpServer.port')
  catch err
    return

  isLibrary = true
  for type in [ 'Collection', 'Search', 'Trash', 'Duplicates', 'Unfiled', 'Header', 'Bucket' ]
    if itemGroup["is#{type}"]()
      isLibrary = false
      break

  if itemGroup.isCollection()
    collection = collectionsView.getSelectedCollection()
    url = "collection?/#{collection.libraryID or 0}/#{collection.key + extension}"

  if isLibrary
    libid = collectionsView.getSelectedLibraryID()
    url = if libid then "library?/#{libid}/library#{extension}" else "library?library#{extension}"
  if not url then return

  return "http://localhost:#{serverPort}/better-bibtex/#{url}"

Zotero.BetterBibTeX.pref.styleChanged = (index) ->
  listbox = document.getElementById('better-bibtex-abbrev-style')
  selectedItem = if index != 'undefined' then listbox.getItemAtIndex(index) else listbox.selectedItem
  styleID = selectedItem.getAttribute('value')
  Zotero.BetterBibTeX.pref.set('auto-abbrev.style', styleID)
  Zotero.BetterBibTeX.keymanager.journalAbbrevCache = Object.create(null)
  return

Zotero.BetterBibTeX.pref.clone = (obj) ->
  clone = Object.create(null)
  for own key, value of obj
    clone[key] = value
  return clone

Zotero.BetterBibTeX.pref._display = (id, text) ->
  elt = document.getElementById(id)
  elt.value = text
  elt.setAttribute('tooltiptext', text) if text != ''
  return

Zotero.BetterBibTeX.pref._collectionPath = (id) ->
  return '' unless id
  coll = Zotero.Collections.get(id)
  return '' unless coll

  return @_collectionPath(coll.parent) + '/' + coll.name if coll.parent
  return coll.name

Zotero.BetterBibTeX.pref.update = ->
  serverCheckbox = document.getElementById('id-better-bibtex-preferences-server-enabled')
  serverEnabled = serverCheckbox.checked
  serverCheckbox.setAttribute('hidden', Zotero.isStandalone && serverEnabled)

  keyformat = document.getElementById('id-better-bibtex-preferences-citeKeyFormat')

  try
    Zotero.BetterBibTeX.formatter(keyformat.value)
    keyformat.setAttribute('style', '')
    keyformat.setAttribute('tooltiptext', '')
  catch err
    keyformat.setAttribute('style', 'color: red')
    keyformat.setAttribute('tooltiptext', '' + err)

  document.getElementById('id-better-bibtex-preferences-pin-citekeys-on-change').setAttribute('disabled', not Zotero.BetterBibTeX.allowAutoPin())
  document.getElementById('id-better-bibtex-preferences-pin-citekeys-on-export').setAttribute('disabled', not Zotero.BetterBibTeX.allowAutoPin())
  document.getElementById('id-zotero-better-bibtex-server-warning').setAttribute('hidden', serverEnabled)
  document.getElementById('id-zotero-better-bibtex-recursive-warning').setAttribute('hidden', not document.getElementById('id-better-bibtex-preferences-getCollections').checked)
  document.getElementById('id-better-bibtex-preferences-fancyURLs-warning').setAttribute('hidden', not document.getElementById('id-better-bibtex-preferences-fancyURLs').checked)

  styles = (style for style in Zotero.Styles.getVisible() when style.usesAbbreviation)

  stylebox = document.getElementById('better-bibtex-abbrev-style')
  refill = stylebox.children.length is 0
  selectedStyle = Zotero.BetterBibTeX.pref.get('auto-abbrev.style')
  selectedIndex = -1
  for style, i in styles
    if refill
      itemNode = document.createElement('listitem')
      itemNode.setAttribute('value', style.styleID)
      itemNode.setAttribute('label', style.title)
      stylebox.appendChild(itemNode)
    if style.styleID is selectedStyle then selectedIndex = i
  selectedIndex = 0 if selectedIndex == -1
  @styleChanged(selectedIndex)

  window.setTimeout((->
    stylebox.ensureIndexIsVisible(selectedIndex)
    stylebox.selectedIndex = selectedIndex
    return), 0)

  exportlist = document.getElementById('better-bibtex-export-list')
  refill = (1 for node in exportlist.children when node.nodeName == 'listitem').length is 0
  Zotero.BetterBibTeX.log('loading exports:', refill, exportlist.children.length)

  selectedExport = -1
  for ae in Zotero.BetterBibTeX.DB.query("select * from autoexport order by collection_name, path")
    selectedExport = 0
    Zotero.BetterBibTeX.log(':::ae', @clone(ae))
    if refill
      itemNode = document.createElement('listitem')
      itemNode.setAttribute('value', ae.id)
      itemNode.setAttribute('label', "#{ae.collection_name} -> #{ae.path.replace(/^.*[\\\/]/, '')}")
      itemNode.setAttribute('class', "export-state-#{if Zotero.BetterBibTeX.auto.running == ae.id then 'running' else ae.status}")
      itemNode.setAttribute('tooltiptext', "#{@_collectionPath(ae.collection_id)} -> #{ae.path}")
      exportlist.appendChild(itemNode)
  @exportSelected(selectedIndex) if selectedExport >= 0

  ca = document.getElementById('id-better-bibtex-preferences-cache-activity')
  ca.value = if Zotero.BetterBibTeX.pref.get('caching') then "+#{Zotero.BetterBibTeX.cache.stats.hits || 0}/-#{Zotero.BetterBibTeX.cache.stats.misses || 0}" else '-'

  return

Zotero.BetterBibTeX.pref.exportSelected = (index) ->
  listbox = document.getElementById('better-bibtex-export-list')
  selectedItem = if index != 'undefined' then listbox.getItemAtIndex(index) else listbox.selectedItem

  ae = Zotero.BetterBibTeX.DB.rowQuery('select * from autoexport where id = ?', [selectedItem.getAttribute('value')])
  ae.context = JSON.parse(ae.context)
  Zotero.BetterBibTeX.log(':::selected', @clone(ae))

  @_display('id-better-bibtex-preferences-auto-export-collection', ae.collection_name)
  @_display('id-better-bibtex-preferences-auto-export-target', ae.path)
  @_display('id-better-bibtex-preferences-auto-export-translator', ae.context.translator)
  @_display('id-better-bibtex-preferences-auto-export-keyformat', ae.context.citeKeyFormat)
  @_display('id-better-bibtex-preferences-auto-export-skipFields', ae.context.skipfields)
  document.getElementById('id-better-bibtex-preferences-auto-export-preserveCaps').checked = ae.context['brace-all']
  document.getElementById('id-better-bibtex-preferences-auto-export-auto-abbrev').checked = ae.context['auto-abbrev'] && ae.context.useJournalAbbreviation
  @_display('id-better-bibtex-preferences-auto-export-auto-abbrev-style', (style.title for style in Zotero.Styles.getVisible() when style.styleID == ae.context['auto-abbrev.style'])?[0] ? '')
  @_display('id-better-bibtex-preferences-auto-export-unicode', switch
    when ae.context.unicode == '' && ae.contex.exportCharset == 'UTF-8'  then 'yes'
    when ae.context.unicode == ''                                        then 'no'
    else ae.context.unicode)
  document.getElementById('id-better-bibtex-preferences-auto-export-notes').checked = ae.context.exportNotes
  return


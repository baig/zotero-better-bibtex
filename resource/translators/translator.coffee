require('bbt-common.coffee')

Translator = new class
  constructor: ->
    @citekeys = Object.create(null)
    @attachmentCounter = 0
    @rawLaTag = '#LaTeX'

    { preferences: @preferences, options: @options } = BBTConfig()
    @BibLaTeXDataFieldMap = Object.create(null)

require(':constants:')

Translator.log = (msg...) ->
  msg = for m in msg
    switch
      when (typeof m) in ['string', 'number'] then '' + m
      when m instanceof Error and m.name then "#{m.name}: #{m.message} \n(#{m.fileName}, #{m.lineNumber})\n#{m.stack}"
      when m instanceof Error then "#{e}\n#{e.stack}"
      else JSON.stringify(m)

  Zotero.debug("[better-bibtex:#{@label}] #{msg.join(' ')}")
  return

Translator.config = ->

  return config

Translator.initialize = ->
  return if @initialized
  @initialized = true

  @caching = Zotero.getHiddenPref('better-bibtex.caching') && @label.indexOf('Better ') == 0

  for own attr, f of @fieldMap or {}
    @BibLaTeXDataFieldMap[f.name] = f if f.name

  for own attribute, key of @preferences
    # prefer options over preferences, for auto-export
    Translator[attribute] = Zotero.getOption(key) ? Zotero.getHiddenPref("better-bibtex.#{key}")
  @skipFields = (field.trim() for field in @skipFields.split(','))
  @testmode = Zotero.getHiddenPref('better-bibtex.testmode')

  for own attribute, key of @options
    Translator[attribute] = Zotero.getOption(key)
  @exportCollections = if typeof @exportCollections == 'undefined' then true else @exportCollections

  @config = Object.create(null)
  @config.id = @id
  @config.label = @label
  @config.release = @release
  @config.preferences = Object.create(null)
  @config.options = Object.create(null)

  for own attribute, key of @preferences
    @config.preferences[key] = Translator[attribute]

  for own attribute, key of @options
    @config.options[key] = Translator[attribute]

  @context = BBTContext(@config)
  @log(":::cache context = #{@context}")

  switch @unicode
    when 'always' then @unicode = true
    when 'never'  then @unicode = false
    else @unicode = @unicode_default or (@exportCharset and @exportCharset.toLowerCase() == 'utf-8')

  @log("Translator: #{JSON.stringify(@config)}")

  if @typeMap
    typeMap = @typeMap
    @typeMap = {
      BibTeX2Zotero: Object.create(null)
      Zotero2BibTeX: Object.create(null)
    }

    for own bibtex, zotero of typeMap
      bibtex = bibtex.trim().split(/\s+/)
      zotero = zotero.trim().split(/\s+/)

      for type in bibtex
        @typeMap.BibTeX2Zotero[type] ?= zotero[0]

      for type in zotero
        @typeMap.Zotero2BibTeX[type] ?= bibtex[0]

# The default collection structure passed is beyond screwed up.
Translator.sanitizeCollection = (coll) ->
  sane = {
    name: coll.name
    collections: []
    items: []
  }

  for c in coll.children or coll.descendents
    switch c.type
      when 'item'       then sane.items.push(c.id)
      when 'collection' then sane.collections.push(@sanitizeCollection(c))
      else              throw "Unexpected collection member type '#{c.type}'"

  return sane

Translator.collections = ->
  return [] unless @exportCollections

  collections = []
  while collection = Zotero.nextCollection()
    collections.push(@sanitizeCollection(collection))
  return collections

Translator.nextItem = ->
  while item = Zotero.nextItem()
    if item.itemType != 'note' and item.itemType != 'attachment' then break
  return unless item

  @initialize()

  cached = if @caching then Zotero.BetterBibTeX.cache.fetch(@context, item.itemID) else null
  @log(':::cache hit?', cached?.citekey)
  if cached?.citekey
    @citekeys[item.itemID] = cached.citekey
    Zotero.write(cached.entry)
    return @nextItem()

  #remove any citekey from extra -- the export doesn't need it
  Zotero.BetterBibTeX.keymanager.extract(item)

  item.__citekey__ = Zotero.BetterBibTeX.keymanager.get(item, 'on-export')
  @citekeys[item.itemID] = item.__citekey__
  return item

Translator.exportGroups = ->
  collections = @collections()
  return if collections.length == 0

  Zotero.write('@comment{jabref-meta: groupsversion:3;}\n')
  Zotero.write('@comment{jabref-meta: groupstree:\n')
  Zotero.write('0 AllEntriesGroup:;\n')

  groups = []
  for collection in collections
    groups = groups.concat(JabRef.exportGroup(collection, 1))

  Zotero.write(JabRef.serialize(groups, ';\n', true) + ';\n}\n')
  return

JabRef = {}

JabRef.serialize = (arr, sep, wrap) ->
  arr = (('' + v).replace(/;/g, "\\;") for v in arr)
  arr = (v.match(/.{1,70}/g).join("\n") for v in arr) if wrap
  return arr.join(sep)

JabRef.exportGroup = (collection, level) ->
  group = ["#{level} ExplicitGroup:#{collection.name}", 0]
  group = group.concat((Translator.citekeys[id] for id in collection.items))
  group.push('')
  group = @serialize(group, ';')

  result = [group]
  for coll in collection.collections
    result = result.concat(JabRef.exportGroup(coll, level + 1))
  return result

class Reference
  constructor: (@item) ->
    Translator.log(':::new reference for', typeof @item, @item)
    @fields = []
    @has = Object.create(null)
    @raw = ((tag.tag for tag in @item.tags when tag.tag == Translator.rawLaTag).length > 0)

    @itemtype = Translator.typeMap.Zotero2BibTeX[@item.itemType] or 'misc'

    if @item.extra
      fields = []
      m = /biblatexdata\[([^\]]+)\]/.exec(@item.extra)
      if m
        @item.extra = @item.extra.replace(m[0], '').trim()
        for assignment in m[1].split(';')
          data = assignment.match(/^([^=]+)=\s*(.*)/)
          unless data
            Zotero.debug("Not an assignment: #{assignment}")
            continue

          fields.push({ name: data[1], value: data[2] })

      m = /(biblatexdata)({[\s\S]+})/.exec(@item.extra)
      if m
        prefix = m[1]
        data = m[2]
        while data.indexOf('}') >= 0
          try
            json = JSON.parse(data)
          catch
            json = null
          break if json
          data = data.replace(/[^}]*}$/, '')
        if json
          @item.extra = @item.extra.replace(prefix + data, '').trim()
          for name, value of json
            fields.push({name: name, value: value})

      for field in fields
        if Translator.BibLaTeXDataFieldMap[field.name]
          field = @field(Translator.BibLaTeXDataFieldMap[field.name], field.value)
        @add(field)

    for own attr, f of Translator.fieldMap or {}
      if f.name and not @has[f.name]
        @add(@field(f, @item[attr]))

Reference::log = Translator.log

Reference::field = (f, value) ->
  clone = Object.create(f)
  clone.value = value
  return clone

Reference::esc_url = (f) ->
  href = ('' + f.value).replace(/([#\\%&{}])/g, '\\$1')
  href = href.replace(/[^\x21-\x7E]/g, ((chr) -> '\\%' + ('00' + chr.charCodeAt(0).toString(16).slice(-2)))) if not Translator.unicode

  return "\\href{#{href}}{#{LaTeX.html2latex(href)}}" if f.name == 'url' and Translator.fancyURLs
  return href

Reference::esc_doi = Reference::esc_url

Reference::esc_latex = (f, raw) ->
  return f.value if typeof f.value == 'number'
  return null unless f.value

  if Array.isArray(f.value)
    return null if f.value.length == 0
    return (@esc_latex(@field(f, word), raw) for word in f.value).join(f.sep)

  return f.value if raw

  value = LaTeX.html2latex(f.value)
  if f.value instanceof String then value = String("{#{value}}")
  return value

Reference::esc_tags = (f) ->
  return null if not f.value or f.value.length == 0
  tags = (tag.tag for tag in f.value when tag.tag != Translator.rawLaTag)

  # sort tags for stable tests
  tags.sort() if Translator.testmode

  f.value = tags
  f.sep = ','
  return @esc_latex(f)

Reference::esc_attachments = (f) ->
  return null if not f.value or f.value.length == 0
  attachments = []
  errors = []

  for att in f.value
    a = {
      title: att.title
      path: att.localPath
      mimetype: att.mimeType
    }

    save = Translator.exportFileData and att.defaultPath and att.saveFile
    a.path = att.defaultPath if save

    continue unless a.path # amazon/googlebooks etc links show up as atachments without a path

    Translator.attachmentCounter += 1
    if save
      att.saveFile(a.path)
    else
      if Translator.attachmentRelativePath
        a.path = "files/#{if Translator.testmode then Translator.attachmentCounter else att.itemID}/#{att.localPath.replace(/.*[\/\\]/, '')}"

    if a.path.match(/[{}]/) # latex really doesn't want you to do this.
      errors.push("BibTeX cannot handle file paths with braces: #{JSON.stringify(a.path)}")
    else
      attachments.push(a)

  if errors.length != 0 then f.errors = errors
  if attachments.length == 0 then return null

  # sort attachments for stable tests
  attachments.sort( ( (a, b) -> a.path.localeCompare(b.path) ) ) if Translator.testmode

  return ((part.replace(/([\\{}:;])/g, "\\$1") for part in [att.title, att.path, att.mimetype]).join(':') for att in attachments).join(';')

Reference::preserveWordCaps = new Zotero.Utilities.XRegExp("
  (^)([\\p{L}]+\\p{Lu}[\\p{L}]*)|
  ([^\\p{L}])([\\p{L}]*\\p{Lu}[\\p{L}]*)
  ".replace(/\s/g, ''), 'g')

Reference::add = (field) ->
  return if Translator.skipFields.indexOf(field.name) >= 0
  return if typeof field.value != 'number' and not field.value
  return if typeof field.value == 'string' and field.value.trim() == ''
  return if Array.isArray(field.value) and field.value.length == 0

  if typeof field.value == 'number'
    value = field.value
  else
    field.preserveCaps = field.preserveCaps and Translator.braceAll
    field.braces = (typeof field.braces == 'undefined') or field.braces or field.preserveCaps or field.value.match(/\s/)
    Translator.log("Escaping #{field.name} with #{field.esc} (raw: #{@raw})")
    value = @["esc_#{field.esc || 'latex'}"](field, (if field.esc then false else @raw))

    return null unless value
    if field.braces
      value = Zotero.Utilities.XRegExp.replace(value, @preserveWordCaps, '${1}${3}{${2}${4}}') if field.preserveCaps && !@raw
      value = "{#{value}}"

  field.bibtex = "  #{field.name} = #{value}"
  @fields.push(field)
  @has[field.name] = true
  return

Reference::complete = ->
  @add({name: 'type', value: @itemtype}) if @fields.length == 0

  if Translator.DOIandURL != 'both'
    doi = (i for field, i in @fields when field.name == 'doi')
    url = (i for field, i in @fields when field.name == 'url')
    if doi.length > 0 && url.length > 0
      switch Translator.DOIandURL
        when 'doi' then @fields.splice(url[0], 1)
        when 'url' then @fields.splice(doi[0], 1)

  # sort fields for stable tests
  if Translator.testmode
    @fields.sort( ((a, b) ->
      _a = a.name
      _b = b.name
      if a.name == b.name
        _a = a.value
        _b = b.value
      if _a < _b then return -1
      if _a > _b then return 1
      return 0) )

  entry = "@#{@itemtype}{#{@item.__citekey__},\n"
  entry += (field.bibtex for field in @fields).join(',\n')
  entry += '\n}\n\n'
  Zotero.write(entry)

  @log(':::ref stores', entry)
  Zotero.BetterBibTeX.cache.store(Translator.context, @item.itemID, @item.__citekey__, entry) if Translator.caching

  return

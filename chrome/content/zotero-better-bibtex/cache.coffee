Zotero.BetterBibTeX.auto = {}

Zotero.BetterBibTeX.auto.add = (state) ->
  options = Object.create(null, state.options || {})
  options.translator = state.translator.id
  delete options['Keep updated']
  for own key, value of Zotero.BetterBibTeX.pref.snapshot() || {}
    switch key
      when 'citeKeyFormat', 'skipfields', 'useprefix', 'brace-all', 'fancyURLs', 'langid', 'attachmentRelativePath', 'auto-abbrev', 'auto-abbrev.style', 'unicode'
        options[key] = value

  # this makes sure the options stringify to a stable key -- json hashes do not preserve order
  keys = Object.keys(options)
  keys.sort()
  values = (options[key] for key in id)

  spec = {
    id: JSON.stringify([id, values])
    path: state.path
    disabled: if state.collection then false else 'Only export of collections is supported'
    collection: state.collection
  }
  return

Zotero.BetterBibTeX.auto.recursive = ->
  try
    return if Zotero.Prefs.get('recursiveCollections') then 'true' else 'false'
  catch
  return 'undefined'

Zotero.BetterBibTeX.cache = {}

Zotero.BetterBibTeX.cache.init = ->
  @__exposedProps__ = {
    fetch: 'r'
    store: 'r'
  }
  for own key, value of @__exposedProps__
    @[key].__exposedProps__ = []

  @stats = {
    hits: 0
    misses: 0
    stores: 0
  }

  return @

Zotero.BetterBibTeX.cache.fetch = (context, itemid) ->
  if context._sandboxManager
    context = arguments[1]
    itemid = arguments[2]

  for cached in Zotero.BetterBibTeX.DB.query('select citekey, entry from cache where context = ? and itemid = ?', [context, itemid])
    cached = {citekey: cached.citekey, entry: cached.entry}
    throw("Malformed cache entry! #{cached}") unless cached.citekey && cached.entry
    @stats.hits += 1
    Zotero.BetterBibTeX.log('::: found cache entry', cached)
    return cached
  @stats.misses += 1
  return null

Zotero.BetterBibTeX.cache.store = (context, itemid, citekey, entry) ->
  if context._sandboxManager
    context = arguments[1]
    itemid = arguments[2]
    citekey = arguments[3]
    entry = arguments[4]

  @stats.stores += 1
  Zotero.BetterBibTeX.log('::: caching entry', [context, itemid, citekey, entry])
  Zotero.BetterBibTeX.DB.query("insert or replace into cache (context, itemid, citekey, entry) values (?, ?, ?, ?)", [context, itemid, citekey, entry])
  return null

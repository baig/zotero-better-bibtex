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

Zotero.BetterBibTeX.cache = {}

Zotero.BetterBibTeX.cache.init = ->
  @__exposedProps__ = {
    fetch: 'r'
    store: 'r'
  }
  for own key, value of @__exposedProps__
    @[key].__exposedProps__ = []

  return @

Zotero.BetterBibTeX.cache.fetch = (context, itemid) ->
  if context._sandboxManager
    context = arguments[1]
    itemid = arguments[2]

  Zotero.BetterBibTeX.DB.query("update cache set timestamp = datetime('now') where context = ? and itemid = ?", [context, itemid])
  return Zotero.BetterBibTeX.DB.rowQuery('select timestamp, ref from cache where context = ? and itemid = ?', [context, itemid])

Zotero.BetterBibTeX.cache.store = (context, itemid, citekey, ref) ->
  if context._sandboxManager
    context = arguments[1]
    itemid = arguments[2]
    citekey = arguments[3]
    ref = arguments[4]

  Zotero.BetterBibTeX.DB.query("insert or replace into cache (context, itemid, citekey, ref, timestamp) values (?, ?, ?, ?, datetime('now'))", [context, itemid, citekey, ref])
  return null

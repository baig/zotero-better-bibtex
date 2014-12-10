# naive json stringifier with ordered object keys
BBTjsonify = (obj) ->
  return '[' + (BBTjsonify(c) for c in obj).join(', ') + ']' if Array.isArray(obj)
  return JSON.stringify(obj) if (typeof obj) in ['number', 'boolean', 'string', 'undefined']
  return JSON.stringify(obj) if obj instanceof String
  return JSON.stringify(obj) if obj == null

  keys = Object.keys(obj)
  keys.sort()
  return '{' + (JSON.stringify(key) + ': ' + BBTjsonify(obj[key]) for key in keys).join(', ') + '}'

BBTConfig = ->
  return {
    preferences: {
      pattern: 'citeKeyFormat'
      skipFields: 'skipfields'
      usePrefix: 'useprefix'
      braceAll: 'brace-all'
      fancyURLs: 'fancyURLs'
      langid: 'langid'
      attachmentRelativePath: 'attachmentRelativePath'
      autoAbbrev: 'auto-abbrev'
      autoAbbrevStyle: 'auto-abbrev.style'
      unicode: 'unicode'
      pinKeys: 'pin-citekeys'
      rawImport: 'raw-imports'
    }
    options: {
      useJournalAbbreviation: 'useJournalAbbreviation'
      exportCharset: 'exportCharset'
      exportFileData: 'exportFileData'
      exportNotes: 'exportNotes'
      exportCollections: 'Export Collections'
    }
  }

BBTContext = (config) ->
  context = Object.create(null)
  context.translator = config.translator ? config.id

  Zotero.debug(':::context from ' + JSON.stringify(config))
  allowed = BBTConfig()
  for section in ['preferences', 'options']
    keys = (val for own key, val of allowed[section])
    for own key, value of config[section]
      Zotero.debug(':::context ' + section + ' allows ' + JSON.stringify(keys))
      continue unless key in keys
      continue if key in ['attachmentRelativePath', 'pin-citekeys', 'exportFileData', 'Export Collections']
      context[key] = value

  return BBTjsonify(context)


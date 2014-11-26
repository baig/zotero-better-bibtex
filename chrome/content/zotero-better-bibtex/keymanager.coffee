Zotero.BetterBibTeX.KeyManager = ->
  # three-letter month abbreviations. I assume these are the same ones that the
  # docs say are defined in some appendix of the LaTeX book. (I don't have the
  # LaTeX book.)
  @months = [ 'jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec' ]
  @journalAbbrevCache = Object.create(null)

  @__exposedProps__ = {
    months: 'r'
    journalAbbrev: 'r'
    extract: 'r'
    get: 'r'
    keys: 'r'
  }
  for own key, value of @__exposedProps__
    @[key].__exposedProps__ = []

Zotero.BetterBibTeX.KeyManager::journalAbbrev = (item) ->
  item = arguments[1] if item._sandboxManager # the sandbox inserts itself in call parameters

  return item.journalAbbreviation if item.journalAbbreviation
  return unless Zotero.BetterBibTeX.prefs.getBoolPref 'auto-abbrev'

  if typeof @journalAbbrevCache[item.publicationTitle] is 'undefined'
    styleID = Zotero.BetterBibTeX.prefs.getCharPref 'auto-abbrev.style'
    styleID = (style for style in Zotero.Styles.getVisible() when style.usesAbbreviation)[0].styleID if styleID is ''
    style = Zotero.Styles.get styleID
    cp = style.getCiteProc true

    cp.setOutputFormat 'html'
    cp.updateItems [item.itemID]
    cp.appendCitationCluster({ citationItems: [{id: item.itemID}], properties: {} } , true)
    cp.makeBibliography()

    abbrevs = cp
    for p in ['transform', 'abbrevs', 'default', 'container-title']
      abbrevs = abbrevs[p] if abbrevs

    for own title,abbr of abbrevs or {}
      @journalAbbrevCache[title] = abbr

    @journalAbbrevCache[item.publicationTitle] ?= ''

  return @journalAbbrevCache[item.publicationTitle]

Zotero.BetterBibTeX.KeyManager::extract = (item) ->
  item = arguments[1] if item._sandboxManager
  item = {extra: item.getField('extra')} if item.getField
  return null unless item.extra

  embeddedKeyRE = /bibtex: *([^\s\r\n]+)/
  andersJohanssonKeyRE = /biblatexcitekey\[([^\]]+)\]/
  extra = item.extra

  m = embeddedKeyRE.exec(item.extra) or andersJohanssonKeyRE.exec(item.extra)
  return null unless m

  item.extra = item.extra.replace(m[0], '').trim()
  return m[1]

Zotero.BetterBibTeX.KeyManager::get = (item, pinmode) ->
  if item._sandboxManager
    item = arguments[1]
    pinmode = arguments[2]

  citekey = Zotero.BetterBibTeX.DB.rowQuery 'select citekey, citeKeyFormat from keys where itemID=? and libraryID = ?', [item.itemID, item.libraryID || 0]
  if not citekey
    pattern = Zotero.BetterBibTeX.prefs.getCharPref 'citeKeyFormat'
    Formatter = Zotero.BetterBibTeX.formatter pattern
    citekey = new Formatter(Zotero.BetterBibTeX.toArray(item)).value
    postfix = { n: -1, c: '' }
    while Zotero.BetterBibTeX.DB.valueQuery 'select count(*) from keys where citekey=? and libraryID = ?', [citekey + postfix.c, item.libraryID || 0]
      postfix.n++
      postfix.c = String.fromCharCode('a'.charCodeAt() + postfix.n)

    citekey = { citekey: citekey + postfix.c, citeKeyFormat: pattern }
    Zotero.BetterBibTeX.DB.query 'delete from keys where libraryID = ? and citeKeyFormat is not null and citekey = ?', [item.libraryID || 0, citekey.citekey]
    Zotero.BetterBibTeX.DB.query 'insert or replace into keys (itemID, libraryID, citekey, citeKeyFormat) values (?, ?, ?, ?)', [ item.itemID, item.libraryID || 0, citekey.citekey, pattern ]

  if citekey.citeKeyFormat && (pinmode == 'manual' || (Zotero.BetterBibTeX.allowAutoPin() && pinmode == Zotero.BetterBibTeX.Prefs.getCharPref('pin-citekeys')))
    item = Zotero.Items.get item.itemID if not item.getField
    _item = {extra: '' + item.getField 'extra'}
    @extract _item
    extra = _item.extra.trim()
    item.setField('extra', "#{extra} \nbibtex: #{citekey.citekey}")
    item.save()

    Zotero.BetterBibTeX.DB.query 'delete from keys where libraryID = ? and citeKeyFormat is not null and citekey = ?', [item.libraryID || 0, citekey.citekey]
    Zotero.BetterBibTeX.DB.query 'insert or replace into keys (itemID, libraryID, citekey, citeKeyFormat) values (?, ?, ?, null)', [ item.itemID, item.libraryID || 0, citekey.citekey ]

  return citekey.citekey

Zotero.BetterBibTeX.KeyManager::keys = ->
  return Zotero.BetterBibTeX.DB.query 'select * from keys order by libraryID, itemID'


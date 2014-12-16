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

  styles = Zotero.Styles.getVisible().filter((style) -> style.usesAbbreviation)

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
  if selectedIndex is -1 then selectedIndex = 0
  @styleChanged(selectedIndex)

  window.setTimeout((->
    stylebox.ensureIndexIsVisible(selectedIndex)
    stylebox.selectedIndex = selectedIndex
    return), 0)

  exportlist = document.getElementById('better-bibtex-export-list')
  refill = (1 for node in exportlist.children when node.nodeName == 'listitem').length is 0
  Zotero.BetterBibTeX.log('loading exports:', refill, exportlist.children.length)
  for exp, i in ['Coll 1', 'Coll 2', 'Coll 3']
    if refill
      Zotero.BetterBibTeX.log('loading exports:', exp)
      itemNode = document.createElement('listitem')
      itemNode.setAttribute('value', exp)
      itemNode.setAttribute('label', exp)
      itemNode.setAttribute('class', 'export-state-running')
      #itemNode.setAttribute('style', 'padding-left: 20px; background:url("chrome://zotero-better-bibtex/skin/ic_sync_24px.svg") center left no-repeat;')
      exportlist.appendChild(itemNode)
  return

Zotero.BetterBibTeX.pref.exportSelected = ->
  stylebox = document.getElementById('better-bibtex-export-list')
  return

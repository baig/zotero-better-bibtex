require('translator.coffee')

scrub = (item) ->
  delete item.__citekey__
  delete item.libraryID
  delete item.key
  delete item.uniqueFields
  delete item.dateAdded
  delete item.dateModified
  delete item.uri
  delete item.multi

  for creator in item.creators or []
    delete creator.creatorID
    delete creator.multi

  item.attachments = ({ path: attachment.localPath, title: attachment.title, mimeType: attachment.mimeType, url: attachment.url } for attachment in item.attachments || [])
  item.notes = (note.note.trim() for note in item.notes || [])

  item.tags = (tag.tag for tag in item.tags || [])
  item.tags.sort()

  for own attr, val of item
    continue if typeof val is 'number'
    continue if Array.isArray(val) and val.length != 0

    switch typeof val
      when 'string'
        delete item[attr] if val.trim() == ''
      when 'undefined'
        delete item[attr]

  return item

detectImport = ->
  json = ''
  while (str = Zotero.read(0x100000)) != false
    json += str

  try
    data = JSON.parse(json)
  catch e
    Translator.log(e)
    return false

  return (data and data.config and data.config.id == Translator.id and data.items)

doImport = ->
  Translator.initialize()

  json = ''
  while (str = Zotero.read(0x100000)) != false
    json += str

  data = JSON.parse(json)

  for i in data.items
    item = new Zotero.Item
    for own prop, value of i
      item[prop] = value
    item.complete()

doExport = ->
  Translator.initialize()
  data = {
    config: Translator.config
    collections: Translator.collections()
    items: []
  }
  while item = Zotero.nextItem()
    data.items.push(scrub(item))
  Zotero.write(JSON.stringify(data, null, '  '))
  return

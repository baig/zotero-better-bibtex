# naive json stringifier with ordered object keys
BBTjsonify = (obj) ->
  return '[' + (BBTjsonify(c) for c in obj).join(', ') + ']' if Array.isArray(obj)
  return JSON.stringify(obj) if (typeof obj) in ['number', 'boolean', 'string', 'undefined']
  return JSON.stringify(obj) if obj instanceof String
  return JSON.stringify(obj) if obj == null

  keys = Object.keys(obj)
  keys.sort()
  return '{' + (JSON.stringify(key) + ': ' + BBTjsonify(obj[key]) for key in keys).join(', ') + '}'

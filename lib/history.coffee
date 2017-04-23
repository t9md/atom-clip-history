module.exports =
class History
  constructor: ->
    @reset()

  reset: ->
    @entries = []
    @resetIndex()

  resetIndex: ->
    @index = -1

  destroy: ->
    [@entries, @index] = []

  add: (text, metadata) ->
    # skip when empty or same text
    return if (text.length is 0) or (text is @entries[0]?.text)
    @entries.unshift {text, metadata}

    # Unique by entry.text
    entries = []
    seen = {}
    for entry in @entries
      seen[entry.text] ?= (entries.push(entry))?
    @entries = entries
    @entries.splice(atom.config.get("clip-history.max"))
    @resetIndex()

  get: (which) ->
    index = @index
    switch which
      when 'newer' then index--
      when 'older' then index++
    @index = @getIndex(index)
    @entries[@index]

  getIndex: (index) ->
    length = @entries.length
    return -1 if length is 0
    index = index % length
    if (index >= 0)
      index
    else
      length + index

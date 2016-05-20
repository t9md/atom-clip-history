_ = require 'underscore-plus'
settings = require './settings'

module.exports =
class History
  constructor: ->
    @reset()

  reset: ->
    @entries = []
    @resetIndex()

  resetIndex: ->
    @index = -1

  # FIFO: newer comes first.
  add: (text, metadata) ->
    # skip when empty or same text
    return if _.isEmpty(text) or (text is @entries[0]?.text)
    @entries.unshift {text, metadata}
    @entries = _.uniq(@entries, (e) -> e.text)

    maxEntries = settings.get('max')
    if @entries.length > maxEntries
      @entries.splice(maxEntries)
    @resetIndex()

  get: (which) ->
    index = switch which
      when 'newer' then @index - 1
      when 'older' then @index + 1
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

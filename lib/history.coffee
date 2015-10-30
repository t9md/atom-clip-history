_ = require 'underscore-plus'
settings = require './settings'

module.exports =
class History
  constructor: ->
    @init()

  init: ->
    @entries = []
    @resetIndex()

  resetIndex: ->
    @index = -1

  add: (text, metadata) => # fat
    return if _.isEmpty(text) or (text is @entries[0]?.text)
    @entries.unshift {text, metadata}
    @entries = _.uniq(@entries, (e) -> e.text)

    maxEntries = settings.get('max')
    if @entries.length > maxEntries
      @entries.splice maxEntries
    @resetIndex()

  get: (which) ->
    index = switch which
      when 'newer' then @index-1
      when 'older' then @index+1
    @index = @getIndex(index, @entries)
    @entries[@index]

  getIndex: (index, list) ->
    return -1 unless list.length
    index = index % list.length
    if (index >= 0) then index else (list.length + index)

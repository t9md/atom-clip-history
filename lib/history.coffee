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
    return if _.isEmpty(text) or (text is @get(0)?.text)
    @entries.unshift {text, metadata}
    @entries = _.uniq(@entries, (e) -> e.text)

    maxEntries = settings.get('max')
    if @entries.length > maxEntries
      @entries.splice maxEntries
    @resetIndex()

  get: (index) ->
    @entries[index]

  getNext: ->
    @get(@index = (@index + 1) % @entries.length)

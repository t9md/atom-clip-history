_ = require 'underscore-plus'
settings = require './settings'

module.exports =
class History
  constructor: ->
    @index   = -1
    @entries = []

  resetIndex: ->
    @index = -1

  clear: ->
    @entries = []

  add: (text, metadata) => # fat
    return if _.isEmpty(text)
    @entries.unshift {text, metadata}
    @entries = _.uniq(@entries, (e) -> e.text)

    maxEntries = settings.get('max')
    if @entries.length > maxEntries
      @entries.splice maxEntries
    @resetIndex()

  getNext: ->
    @index = (@index + 1) % @entries.length
    @entries[@index]

  getLatest: ->
    @entries[0]

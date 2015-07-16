_ = require 'underscore-plus'

module.exports =
class History
  entries: []
  index: 0

  constructor: (@max) ->
    @index   = 0
    @entries = []

  resetIndex: ->
    @index = 0

  clear: ->
    @entries = []

  uniq: (entries) ->
    seen = []
    entries.filter (e) ->
      if e.text in seen
        false
      else
        seen.push e.text
        true

  add: (text, metadata) ->
    return if _.isEmpty(text)
    @entries.unshift {text, metadata}
    @entries = @uniq @entries
    @entries.pop() if @entries.length > @max
    @index = 0

  get: (index) ->
    @entries[index]

  # dump: ->
  #   console.log "index = #{@index}, length = #{@entries.length}"
  #   for entry, i in @entries
  #     current = if @index is i then '> ' else '  '
  #     console.log "#{current}#{i} #{entry.text}"

  peekLatest: ->
    @get 0

  getNext: ->
    entry = @get @index
    if entry
      @index = (@index + 1) % @entries.length
    entry

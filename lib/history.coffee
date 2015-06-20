_ = require 'underscore-plus'

module.exports =
class History
  entries: []
  index: 0

  constructor: (@max) ->
    @index   = 0
    @entries = []

  resetIndex: ->
    @index = @entries.length - 1

  clear: ->
    @entries = []

  add: (text, metadata) ->
    # Don't store duplicate text
    if text in _.pluck(@entries, 'text')
      return

    @entries.shift() if @entries.length is @max
    @entries.push {text, metadata}
    @index = @entries.length - 1

  get: (index) ->
    @entries[index]

  dump: ->
    console.log "index = #{@index}, length = #{@entries.length}"
    for entry, i in @entries
      current = if @index is i then '> ' else '  '
      console.log "#{current}#{i} #{entry.text}"

  getNext: ->
    entry = @get @index
    if entry
      @index -= 1
      if @index < 0
        @index = @entries.length - 1
    entry

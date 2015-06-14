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
    @index = 0
    @entries = []

  add: (entry) ->
    # Don't store duplicate text
    if entry.text in _.pluck(@entries, 'text')
      return
      
    @entries.shift() if @entries.length is @max
    @entries.push entry
    @index = @entries.length - 1

  get: (index) ->
    @entries[index]

  dump: ->
    console.log "index = #{@index}, length = #{@entries.length}"
    for entry, i in @entries
      current = if @index is i then '> ' else '  '
      console.log "#{current}#{i} #{entry.text}"

  getLast: (index) ->
    _.last @entries

  getOlder: ->
    @index -= 1
    if @index < 0
      @index = @entries.length - 1
    @get @index

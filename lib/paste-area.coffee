module.exports =
class PasteArea
  constructor: ->
    @markerByCursor = new Map

  has: (cursor) ->
    @markerByCursor.has(cursor)

  getRange: (cursor) ->
    @markerByCursor.get(cursor)?.getBufferRange()

  update: (cursor, marker) ->
    @markerByCursor.get(cursor)?.destroy()
    @markerByCursor.set(cursor, marker)

  clear: ->
    @markerByCursor.forEach((marker) -> marker.destroy())
    @markerByCursor.clear()

  isEmpty: ->
    @markerByCursor.size is 0

  destroy: ->
    @clear()
    [@markerByCursor] = []

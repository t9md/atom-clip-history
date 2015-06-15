module.exports =
class Flasher
  constructor: (@editor, range) ->
    @marker = @editor.markBufferRange range,
      invalidate: 'never'
      persistent: false

  flash: (duration) ->
    @decoration = @editor.decorateMarker @marker,
      type: 'highlight'
      class: "clip-history-pasted-range"

    setTimeout  =>
      @decoration.getMarker().destroy()
    , duration

  @register: (editor, range) ->
    @flashers ?= []
    @flashers.push new this(editor, range)

  @flash: (duration) ->
    for flasher in @flashers
      flasher.flash(duration)
    @flashers = null

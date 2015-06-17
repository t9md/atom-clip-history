module.exports =
class Flasher
  constructor: (@editor, @marker) ->

  flash: ({color, duration, persist}) ->
    @decoration = @editor.decorateMarker @marker,
      type: 'highlight'
      class: "clip-history-#{color}"

    return if persist

    setTimeout  =>
      @decoration.getMarker().destroy()
    , duration

  @register: (editor, marker) ->
    @flashers ?= []
    @flashers.push new this(editor, marker)

  @flash: (options) ->
    for flasher in @flashers
      flasher.flash(options)
    @flashers = null

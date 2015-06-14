settings = require './settings'

module.exports =
class Flasher
  @flash: (editor, range) =>
    @clear()

    marker = editor.markBufferRange range,
      invalidate: 'never'
      persistent: false

    @decoration = editor.decorateMarker marker,
      type: 'highlight'
      class: "clip-history-pasted-range"

    @timeoutID = setTimeout  =>
      @decoration.getMarker().destroy()
    , settings.get('flashDurationMilliSeconds')

  @clear: =>
    @decoration?.getMarker().destroy()
    clearTimeout @timeoutID

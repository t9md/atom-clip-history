adjustIndent = null

CONFIG =
  max:
    order: 0
    type: 'integer'
    default: 10
    minimum: 1
    description: "Number of history to remember"
  flashOnPaste:
    order: 1
    type: 'boolean'
    default: true
    description: "Flash when pasted"
  adjustIndent:
    order: 2
    type: 'boolean'
    default: true
    description: "Keep layout of pasted text by adjusting indentation."
  doNormalPasteWhenMultipleCursors:
    order: 3
    type: 'boolean'
    default: true
    description: "Keep layout of pasted text by adjusting indentation."

module.exports =
  config: CONFIG
  lastPastedText: null
  pasting: false

  activate: ->
    @atomClipboardWrite = atom.clipboard.write
    atom.clipboard.write = (args...) =>
      @history ?= @createHistory()
      @history.add(args...)
      @atomClipboardWrite.call(atom.clipboard, args...)

    @comandsDisposable = atom.commands.add 'atom-text-editor',
      'clip-history:paste': => @paste('older')
      'clip-history:paste-newer': => @paste('newer')
      'clip-history:paste-last': => @paste('lastPasted')
      'clip-history:clear': => @history?.reset()

  deactivate: ->
    atom.clipboard.write = @atomClipboardWrite
    @pasteArea?.destroy()
    @history?.destroy()
    @comandsDisposable.dispose()
    [@pasteArea, @history, @lastPastedText, @comandsDisposable] = []

  createHistory: ->
    new (require('./history'))

  createPasteArea: ->
    new (require('./paste-area'))

  resetPasteState: ->
    @pasteArea?.clear()
    @history?.resetIndex()

  paste: (which) ->
    @history ?= @createHistory()
    @pasteArea ?= @createPasteArea()

    editor = atom.workspace.getActiveTextEditor()
    if editor.hasMultipleCursors() and atom.config.get("clip-history.doNormalPasteWhenMultipleCursors")
      editor.pasteText()
      return

    if @pasteArea.isEmpty() # means first paste
      # system's clipboad can be updated in outer world.
      @history.add(atom.clipboard.read())

    if which is 'lastPasted'
      @resetPasteState()
      text = @lastPastedText
    else
      text = @history.get(which).text
    return unless text

    @cursorChangeDisposable ?= editor.onDidChangeCursorPosition =>
      unless @pasting
        @resetPasteState()
        @cursorChangeDisposable.dispose()
        @cursorChangeDisposable = null

    @pasting = true
    for cursor in editor.getCursors()
      @insertText(cursor, text)
    editor.scrollToCursorPosition(center: false)
    @lastPastedText = text
    @pasting = false

  insertText: (cursor, text) ->
    editor = cursor.editor
    range = @pasteArea.getRange(cursor) ? cursor.selection.getBufferRange()
    if atom.config.get("clip-history.adjustIndent") and text.endsWith("\n")
      adjustIndent ?= require('./adjust-indent')
      text = adjustIndent(text, {editor, indent: ' '.repeat(range.start.column)})

    marker = editor.markBufferRange(editor.setTextInBufferRange(range, text))
    @pasteArea.update(cursor, marker)

    if atom.config.get("clip-history.flashOnPaste")
      markerForFlash = marker.copy()
      editor.decorateMarker(markerForFlash, type: 'highlight', class: 'clip-history-pasted')
      setTimeout  ->
        markerForFlash.destroy()
      , 1000

adjustIndent = null
PasteArea = require './paste-area'

module.exports =
class History
  lastPastedText: null
  pasting: false

  constructor: ->
    @pasteArea = new PasteArea
    @clear()

  clear: ->
    @entries = []
    @resetIndex()

  resetPasteState: ->
    @pasteArea.clear()
    @resetIndex()

  resetIndex: ->
    @index = -1

  destroy: ->
    @pasteArea.destroy()
    @cursorChangeDisposable?.dispose()

  add: (text, metadata) ->
    # skip when empty or same text
    return if (text.length is 0) or (text is @entries[0]?.text)
    @entries.unshift {text, metadata}

    # Unique by entry.text
    entries = []
    seen = {}
    for entry in @entries
      seen[entry.text] ?= (entries.push(entry))?
    @entries = entries
    @entries.splice(atom.config.get("clip-history.max"))
    @resetIndex()

  get: (which) ->
    index = @index
    switch which
      when 'newer' then index--
      when 'older' then index++
    @index = @getIndex(index)
    @entries[@index]

  getIndex: (index) ->
    length = @entries.length
    return -1 if length is 0
    index = index % length
    if (index >= 0)
      index
    else
      length + index

  paste: (which) ->
    editor = atom.workspace.getActiveTextEditor()
    if editor.hasMultipleCursors() and atom.config.get("clip-history.doNormalPasteWhenMultipleCursors")
      editor.pasteText()
      return

    if @pasteArea.isEmpty() # means first paste
      # system's clipboad can be updated in outer world.
      @add(atom.clipboard.read())

    if which is 'lastPasted'
      @resetPasteState()
      text = @lastPastedText
    else
      text = @get(which).text
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

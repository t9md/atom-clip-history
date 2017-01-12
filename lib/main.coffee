{CompositeDisposable, Disposable} = require 'atom'
_ = require 'underscore-plus'

{adjustIndent, spyClipBoardWrite} = require './utils'

settings = require './settings'
History = require './history'
PasteArea = require './paste-area'

module.exports =
  config: settings.config
  lastPastedText: null

  activate: ->
    settings.notifyOldParamsAndDelete()

    @history = new History
    addHistory = @history.add.bind(@history)
    @restoreClipBoardWrite = spyClipBoardWrite(addHistory)
    @pasteArea = new PasteArea

    @subscriptions = new CompositeDisposable
    @subscriptions.add new Disposable =>
      @pasteArea.destroy()
      @history.destroy()
      [@pasteArea, @history] = []

    paste = @paste.bind(this)
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'clip-history:paste': -> paste(@getModel(), 'older')
      'clip-history:paste-newer': -> paste(@getModel(), 'newer')
      'clip-history:paste-last': -> paste(@getModel(), 'lastPasted')
      'clip-history:clear': => @history.reset()

  deactivate: ->
    @restoreClipBoardWrite()
    @subscriptions.dispose()
    [@lastPastedText, @subscriptions, @restoreClipBoardWrite] = []

  resetPasteState: ->
    @pasteArea.clear()
    @history.resetIndex()

  observeCursorChange: (editor) ->
    editor.onDidChangeCursorPosition =>
      unless @pasting
        @resetPasteState()
        @cursorChangeDisposable.dispose()
        @cursorChangeDisposable = null

  startPaste: (fn) ->
    try
      @pasting = true
      fn()
    finally
      @pasting = false

  paste: (editor, which) ->
    if editor.hasMultipleCursors() and settings.get('doNormalPasteWhenMultipleCursors')
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

    @cursorChangeDisposable ?= @observeCursorChange(editor)
    @startPaste =>
      for cursor in editor.getCursors()
        @insertText(cursor, text)
      editor.scrollToCursorPosition(center: false)
      @lastPastedText = text

  insertText: (cursor, text) ->
    editor = cursor.editor
    range = @pasteArea.getRange(cursor) ? cursor.selection.getBufferRange()
    if settings.get('adjustIndent') and text.endsWith("\n")
      text = adjustIndent(text, {editor, indent: ' '.repeat(range.start.column)})

    marker = editor.markBufferRange(editor.setTextInBufferRange(range, text))
    @pasteArea.update(cursor, marker)

    if settings.get('flashOnPaste')
      markerForFlash = marker.copy()
      editor.decorateMarker(markerForFlash, type: 'highlight', class: 'clip-history-pasted')
      setTimeout  ->
        markerForFlash.destroy()
      , 1000

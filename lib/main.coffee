{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'

{adjustIndent, spyClipBoardWrite} = require './utils'

settings = require './settings'
History = require './history'

module.exports =
  config: settings.config

  activate: ->
    @history = new History
    @markerByCursor = new Map
    addHistory = @history.add.bind(@history)
    @restoreClipBoardWrite = spyClipBoardWrite(addHistory)

    settings.notifyOldParamsAndDelete()
    @subscriptions = new CompositeDisposable

    paste = @paste.bind(this)
    @subscribe atom.commands.add 'atom-text-editor',
      'clip-history:paste': -> paste(@getModel(), 'older')
      'clip-history:paste-newer': -> paste(@getModel(), 'newer')
      'clip-history:paste-last': -> paste(@getModel(), 'lastPasted')
      'clip-history:clear': => @history.reset()

  subscribe: (args) ->
    @subscriptions.add(args)

  deactivate: ->
    @restoreClipBoardWrite()
    @resetPasteState()
    @subscriptions.dispose()
    {@lastPastedText, @subscriptions, @restoreClipBoardWrite} = {}

  resetPasteState: ->
    @markerByCursor.forEach((marker) -> marker.destroy())
    @markerByCursor.clear()
    @history.resetIndex()

  observeCursorChange: (editor) ->
    return if @cursorChangeDisposable?
    @cursorChangeDisposable = editor.onDidChangeCursorPosition =>
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

    if @markerByCursor.size is 0 # means first paste
      # system's clipboad can be updated in outer world.
      @history.add(atom.clipboard.read())

    if which is 'lastPasted'
      @resetPasteState()
      text = @lastPastedText
    else
      text = @history.get(which).text
    return unless text

    @observeCursorChange(editor)
    @startPaste =>
      for cursor in editor.getCursors()
        @insertText(cursor, text)
      editor.scrollToCursorPosition(center: false)
    @lastPastedText = text

  getPasteRangeForCursor: (cursor) ->
    if @markerByCursor.has(cursor)
      @markerByCursor.get(cursor).getBufferRange()
    else
      cursor.selection.getBufferRange()

  insertText: (cursor, text) ->
    editor = cursor.editor
    range = @getPasteRangeForCursor(cursor)
    if settings.get('adjustIndent') and text.endsWith("\n")
      text = adjustIndent text,
        indent: ' '.repeat(range.start.column)
        softTabs: editor.getSoftTabs()
        tabLength: editor.getTabLength()

    @markerByCursor.get(cursor)?.destroy()

    newTextRange = editor.setTextInBufferRange(range, text)
    marker = editor.markBufferRange(newTextRange)
    @markerByCursor.set(cursor, marker)
    if settings.get('flashOnPaste')
      @flash(editor, marker.copy(), settings.get('flashDurationMilliSeconds'))

  flash: (editor, marker, timeout=0) ->
    editor.decorateMarker(marker, type: 'highlight', class: 'clip-history-pasted')
    setTimeout  ->
      marker.destroy()
    , timeout

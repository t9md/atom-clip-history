{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'

{getEditor, adjustIndent, flash, spyClipBoardWrite} = require './utils'
settings = require './settings'
History = require './history'

module.exports =
  config: settings.config

  activate: (state) ->
    @history = new History(settings.get('max'))
    @markerByCursor = new Map
    @restoreClipBoardWrite = spyClipBoardWrite(@history.add)

    @subscriptions = subs = new CompositeDisposable
    subs.add atom.commands.add 'atom-text-editor',
      'clip-history:paste': => @paste()
      'clip-history:paste-last': => @paste({pasteLastPasted: true})
      'clip-history:clear': => @clear()

    # To clear pasteState on pane item changed
    subs.add atom.workspace.onDidChangeActivePaneItem (item) =>
      @resetPasteState()

    # To clear pasteState on cursor position changed
    subs.add atom.workspace.observeTextEditors (editor) =>
      return if editor.isMini()
      editorSubs = new CompositeDisposable
      # CursorMoved
      editorSubs.add editor.onDidChangeCursorPosition =>
        @resetPasteState() unless @isPasting()

      editorSubs.add editor.onDidDestroy ->
        editorSubs.dispose()
        subs.remove(editorSubs)

      subs.add editorSubs

  deactivate: ->
    @restoreClipBoardWrite()
    @resetPasteState()
    @subscriptions.dispose()
    {@lastPastedText, @subscriptions, @restoreClipBoardWrite} = {}

  resetPasteState: ->
    @markerByCursor.forEach (marker) ->
      marker.destroy()
    @markerByCursor.clear()
    @history.resetIndex()

  startPaste: (fn) ->
    @pasting = true
    try
      fn()
    finally
      @pasting = false

  isPasting: ->
    @pasting

  clear: ->
    @history.clear()

  syncSystemClipboard: ->
    clipboadText = atom.clipboard.read()
    if clipboadText isnt @history.getLatest()?.text
      @history.add clipboadText

  paste: ({pasteLastPasted}={}) ->
    if @markerByCursor.size is 0 # means first paste
      # system's clipboad might be updated in other place.
      @syncSystemClipboard()

    if pasteLastPasted?
      text = @lastPastedText
      @resetPasteState()
    else
      text = @history.getNext()?.text
    return unless text

    editor = getEditor()
    @startPaste =>
      editor.transact =>
        @setText(c, text) for c in editor.getCursors()
      editor.scrollToCursorPosition {center: false}
    @lastPastedText = text

  getPasteRangeForCursor: (cursor) ->
    if @markerByCursor.has(cursor)
      @markerByCursor.get(cursor).getBufferRange()
    else
      cursor.selection.getBufferRange()

  setText: (cursor, text) ->
    range = @getPasteRangeForCursor(cursor)
    editor = cursor.editor
    if settings.get('adjustIndent')
      text = adjustIndent(text, editor, range.start)

    newRange = editor.setTextInBufferRange(range, text)
    marker = editor.markBufferRange newRange,
      invalidate: 'never'
      persistent: false

    @markerByCursor.get(cursor)?.destroy()
    @markerByCursor.set(cursor, marker)

    if settings.get('flashOnPaste')
      flashMarker = if settings.get('flashPersist') then marker else marker.copy()
      flash editor, flashMarker,
        class: 'clip-history-pasted'
        duration: settings.get('flashDurationMilliSeconds')
        persist: settings.get('flashPersist')

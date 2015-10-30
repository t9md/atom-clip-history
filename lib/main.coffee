{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'

{adjustIndent, flash, spyClipBoardWrite} = require './utils'
settings = require './settings'
History = require './history'

module.exports =
  config: settings.config

  activate: (state) ->
    @history = new History
    @markerByCursor = new Map
    @restoreClipBoardWrite = spyClipBoardWrite(@history.add)

    @subscriptions = subs = new CompositeDisposable
    subs.add atom.commands.add 'atom-text-editor',
      'clip-history:paste': => @paste('older')
      'clip-history:paste-newer': => @paste('newer')
      'clip-history:paste-last': => @paste('lastPasted')
      'clip-history:clear': => @history.init()

    # Reset pasteState when pane item changed
    subs.add atom.workspace.onDidChangeActivePaneItem (item) =>
      @resetPasteState()
    @observeCursorPositionChange()

  # Reset pasteState when cursor position changed
  observeCursorPositionChange: ->
    subs = @subscriptions
    subs.add atom.workspace.observeTextEditors (editor) =>
      return if editor.isMini()
      editorSubs = new CompositeDisposable
      editorSubs.add editor.onDidChangeCursorPosition =>
        if not @isPasting() and (@markerByCursor.size > 0)
          @resetPasteState()

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

  paste: (which) ->
    if @markerByCursor.size is 0 # means first paste
      # system's clipboad can be updated in other place.
      @history.add atom.clipboard.read()

    if which is 'lastPasted'
      @resetPasteState()
      text = @lastPastedText
    else
      text = @history.get(which).text
    return unless text

    editor = atom.workspace.getActiveTextEditor()
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
    editor = cursor.editor
    range = @getPasteRangeForCursor(cursor)
    if settings.get('adjustIndent')
      text = adjustIndent text,
        indent: _.multiplyString(' ', range.start.column) ? ''
        softTabs: editor.getSoftTabs()
        tabLength: editor.getTabLength()

    range = editor.setTextInBufferRange(range, text)
    marker = editor.markBufferRange range,
      invalidate: 'never'
      persistent: false

    @markerByCursor.get(cursor)?.destroy()
    @markerByCursor.set(cursor, marker)

    if settings.get('flashOnPaste')
      flash editor, marker,
        class: 'clip-history-pasted'
        duration: settings.get('flashDurationMilliSeconds')
        persist: settings.get('flashPersist')

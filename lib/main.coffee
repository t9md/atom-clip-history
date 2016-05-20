{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'

{adjustIndent, spyClipBoardWrite} = require './utils'

settings = require './settings'
History = require './history'

module.exports =
  config: settings.config

  activate: (state) ->
    @history = new History
    @markerByCursor = new Map
    addHistory = @history.add.bind(@history)
    @restoreClipBoardWrite = spyClipBoardWrite(addHistory)

    settings.notifyOldParamsAndDelete()
    @subscriptions = new CompositeDisposable

    @subscribe atom.commands.add 'atom-text-editor',
      'clip-history:paste': => @paste('older')
      'clip-history:paste-newer': => @paste('newer')
      'clip-history:paste-last': => @paste('lastPasted')
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

  startPaste: (editor, fn) ->
    disposable = editor.onDidChangeCursorPosition =>
      if not @pasting and (@markerByCursor.size > 0)
        @resetPasteState()
        disposable.dispose()

    try
      @pasting = true
      fn()
    finally
      @pasting = false

  paste: (which) ->
    editor = atom.workspace.getActiveTextEditor()
    if editor.hasMultipleCursors() and settings.get('doNormalPasteWhenMultipleCursors')
      editor.pasteText()
      return

    if @markerByCursor.size is 0 # means first paste
      # system's clipboad can be updated in outer world.
      @history.add atom.clipboard.read()

    if which is 'lastPasted'
      @resetPasteState()
      text = @lastPastedText
    else
      text = @history.get(which).text
    return unless text

    @startPaste editor, =>
      for cursor in editor.getCursors()
        @setText(cursor, text)
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
    if settings.get('adjustIndent') and text.endsWith("\n")
      text = adjustIndent text,
        indent: _.multiplyString(' ', range.start.column) ? ''
        softTabs: editor.getSoftTabs()
        tabLength: editor.getTabLength()

    range = editor.setTextInBufferRange(range, text)
    marker = editor.markBufferRange(range, invalidate: 'never')
    @markerByCursor.get(cursor)?.destroy()
    @markerByCursor.set(cursor, marker)
    @flash(editor, marker.copy()) if settings.get('flashOnPaste')

  flash: (editor, marker) ->
    options = {type: 'highlight', class: 'clip-history-pasted'}
    timeout = settings.get('flashDurationMilliSeconds')
    editor.decorateMarker(marker, options)
    setTimeout  ->
      marker.destroy()
    , timeout

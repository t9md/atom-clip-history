{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'

{getEditor, adjustIndent, flash} = require './utils'
settings = require './settings'

History = require './history'

module.exports =
  config: settings.config
  subscriptions:      null
  history:            null
  lastPastedText:     null

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @history = new History(settings.get('max'))
    @markerByCursor = new Map
    @restoreNativeClipBoardWrite = @extendNativeClipBoardWrite()
    @subscriptions.add atom.commands.add 'atom-text-editor',
      'clip-history:paste': => @paste()
      'clip-history:paste-last': => @paste({pasteLastPasted: true})
      'clip-history:clear': => @clear()

  extendNativeClipBoardWrite: ->
    atomClipboardWrite = atom.clipboard.write
    atom.clipboard.write = (params...) =>
      @history.add(params...)
      atomClipboardWrite.call(atom.clipboard, params...)
    ->
      atom.clipboard.write = atomClipboardWrite

  deactivate: ->
    @restoreNativeClipBoardWrite?()
    @subscriptions.dispose()
    {@lastPastedText, @subscriptions, @restoreNativeClipBoardWrite} = {}

  withLock: (fn) ->
    @locked = true
    fn()
    @locked = false

  isLocked: -> @locked
  clear: -> @history.clear()

  paste: ({pasteLastPasted}={}) ->
    text = if pasteLastPasted? then @lastPastedText else @history.getNext()?.text
    return unless text

    if (initialPaste = @markerByCursor.size is 0)
      # system's clipboad might be updated in other place.
      @syncSystemClipboard()
      @registerCleanUp()

    getRange = (cursor) =>
      if pasteLastPasted? or initialPaste
        cursor.selection.getBufferRange()
      else
        @markerByCursor.get(cursor)?.getBufferRange()

    editor = getEditor()
    @withLock =>
      editor.transact =>
        @setText(c, getRange(c), text) for c in editor.getCursors()
      editor.scrollToCursorPosition {center: false}
    @lastPastedText = text

  setText: (cursor, range, text) ->
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
        class: "clip-history-#{settings.get('flashColor')}"
        duration: settings.get('flashDurationMilliSeconds')
        persist: settings.get('flashPersist')

  registerCleanUp: ->
    @subscriptions.add sub = getEditor().onDidChangeCursorPosition =>
      return if @isLocked()
      @markerByCursor.forEach (marker) ->
        marker.destroy()
      @markerByCursor.clear()
      @history.reset()
      sub.dispose()
      @subscriptions.remove(sub)

  syncSystemClipboard: ->
    clipboadText = atom.clipboard.read()
    if clipboadText isnt @history.getLatest()?.text
      @history.add clipboadText

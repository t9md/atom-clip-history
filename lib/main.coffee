{CompositeDisposable} = require 'atom'
_ = require 'underscore-plus'
settings = require './settings'

module.exports =
  config: settings.config

  disposables:        null
  history:            null
  lastPastedRanges:   null
  lastPastedText:     null
  atomClipboardWrite: null
  flasher:            null
  pasteSubscription:  null

  activate: (state) ->
    @disposables = new CompositeDisposable

    History = require './history'
    @history = new History(settings.get('max'))

    @lastPastedRanges = {}

    # texts = ['111', '222', '333']
    # @history.add text for text in texts

    # Extending atom's native clipborad
    @atomClipboardWrite = atom.clipboard.write
    atom.clipboard.write = (params...) =>
      @history.add params...
      @atomClipboardWrite.call atom.clipboard, params...

    @disposables.add atom.commands.add 'atom-workspace',
      'clip-history:paste':      => @paste()
      'clip-history:paste-last': => @paste(last: true)
      'clip-history:clear':      => @clear()

  lock: ->
    @locked = true

  unLock: ->
    @locked = false

  isLocked: ->
    @locked

  dump: ->
    console.log @lastPastedRanges[@getEditor().getLastCursor().id]
    @history.dump()

  clear: ->
    @history.clear()

  deactivate: ->
    @lastPastedText = null
    if @atomClipboardWrite?
      atom.clipboard.write = @atomClipboardWrite
    @pasteSubscription?.dispose()
    @disposables.dispose()

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  getFlasher: ->
    @flasher ?= require './flasher'

  setText: (cursor, range, text) ->
    editor = cursor.editor
    newRange = editor.setTextInBufferRange range, text

    marker = editor.markBufferRange newRange,
      invalidate: 'never'
      persistent: false

    @lastPastedRanges[cursor.id]?.destroy()
    @lastPastedRanges[cursor.id] = marker

    return unless settings.get('flashOnPaste')

    flashMarker =
      if settings.get('flashPersist')
        marker
      else
        marker.copy()

    @getFlasher().register editor, flashMarker

  setTextForCursors: (text, rangeProider) ->
    editor = @getEditor()

    @lock()
    editor.transact =>
      for cursor in editor.getCursors()
        @setText cursor, rangeProider(cursor), text
    @unLock()

    @lastPastedText = text
    return unless settings.get('flashOnPaste')

    @getFlasher().flash
      color:    settings.get('flashColor')
      duration: settings.get('flashDurationMilliSeconds')
      persist:  settings.get('flashPersist')

  registerCleanUp: ->
    @pasteSubscription = @getEditor().onDidChangeCursorPosition (event) =>
      return if @isLocked()

      for cursor, marker of @lastPastedRanges
        marker.destroy()

      @lastPastedRanges = {}
      @history.resetIndex()
      @pasteSubscription.dispose()
      @pasteSubscription = null

  getRangeProvider: (rangeType) ->
    switch rangeType
      when 'current'
        (cursor) -> cursor.selection.getBufferRange()
      when 'lastPasted'
        (cursor) => @lastPastedRanges[cursor.id]?.getBufferRange()

  paste: (options={}) ->
    return unless editor = @getEditor()

    rangeType = null
    if options.last?
      text = @lastPastedText
      rangeType = 'current'
    else
      text = @history.getNext()?.text
    return unless text

    if not @pasteSubscription?
      # First time
      rangeType ?= 'current'
      @registerCleanUp()
    else
      rangeType ?= 'lastPasted'

    @setTextForCursors text, @getRangeProvider(rangeType)

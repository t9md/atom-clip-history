{CompositeDisposable} = require 'atom'
settings   = require './settings'

module.exports =
  config: settings.config

  disposables:        null
  history:            null
  lastPastedRange:    null
  lastPastedText:     null
  atomClipboardWrite: null
  flasher:            null
  pasteSubscription:  null

  activate: (state) ->
    @disposables = new CompositeDisposable

    History = require './history'
    @history = new History(100)

    @lastPastedRange = {}

    # Extending atom's native clipborad
    @atomClipboardWrite = atom.clipboard.write.bind(atom.clipboard)
    atom.clipboard.write = (text, metadata) =>
      @history.add({text, metadata})
      @atomClipboardWrite(text, metadata)

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
    console.log @lastPastedRange[@getEditor().getLastCursor().id]
    @history.dump()

  clear: ->
    @history.clear()

  deactivate: ->
    @lastPastedText = null
    @disposables.dispose()
    if @atomClipboardWrite?
      atom.clipboard.write = @atomClipboardWrite
    @pasteSubscription?.dispose()

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  getFlasher: ->
    @flasher ?= require './flasher'

  setText: (cursor, range, text) ->
    editor = cursor.editor
    newRange = editor.setTextInBufferRange range, text
    if settings.get('flashOnPaste')
      @getFlasher().flash editor, newRange
    @lastPastedRange[cursor.id] = newRange

  # callback() need to return Range to be replaced.
  setTextForCursors: (text, callback) ->
    pasted = null

    @lock()
    for cursor in @getEditor().getCursors()
      break unless range = callback(cursor)
      pasted = true
      @setText cursor, range, text
    @unLock()
    @lastPastedText = text if pasted

  registerCleanUp: ->
    @pasteSubscription = @getEditor().onDidChangeCursorPosition (event) =>
      return if @isLocked()
      # console.log "onDidChange clear subscription!"
      @lastPastedRange = {}
      @history.resetIndex()

      @pasteSubscription.dispose()
      @pasteSubscription = null

  getRangeProvider: (rangeType) ->
    switch rangeType
      when 'current'
        (cursor) -> cursor.selection.getBufferRange()
      when 'lastPasted'
        (cursor) => @lastPastedRange[cursor.id]

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

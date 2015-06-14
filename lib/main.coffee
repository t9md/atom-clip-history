{CompositeDisposable} = require 'atom'
settings   = require './settings'

module.exports =
  config: settings.config
  disposables:     null
  history:         null
  lastPastedRange: null
  clipboardWrite:  null
  flasher:         null

  activate: (state) ->
    @disposables = new CompositeDisposable

    History = require './history'
    @history = new History(100)

    @lastPastedRange = {}
    @extendClipboard()

    @disposables.add atom.commands.add 'atom-workspace',
      'clip-history:paste':       => @paste()
      'clip-history:paste-older': => @pasteOlder()
      'clip-history:clear':       => @clear()

  extendClipboard: ->
    clipboard = atom.clipboard
    @clipboardWrite = clipboard.write
    atom.clipboard.write = (text, metadata) =>
      @history.add({text, metadata})
      @clipboardWrite.call(clipboard, text, metadata)

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
    @disposables.dispose()
    if @clipboardWrite?
      atom.clipboard.write = @clipboardWrite

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  getFlasher: ->
    @flasher ?= require './flasher'

  resetState: ->
    @lastPastedRange = {}
    @history.resetIndex()

  setText: (cursor, range, text) ->
    editor = cursor.editor
    newRange = editor.setTextInBufferRange range, text
    if settings.get('flashOnPaste')
      @getFlasher().flash editor, newRange
    @lastPastedRange[cursor.id] = newRange

  paste: ->
    return unless editor = @getEditor()
    return unless text = @history.getLast()?.text

    @resetState()
    @pasteSubscription?.dispose()

    for cursor in editor.getCursors()
      range = cursor.selection.getBufferRange()
      @setText cursor, range, text

    @pasteSubscription = editor.onDidChangeCursorPosition (event) =>
      return if @isLocked()
      @resetState()
      # @dump()
      @pasteSubscription.dispose()
    # @dump()

  pasteOlder: ->
    return unless editor = @getEditor()
    return unless text = @history.getOlder()?.text

    @lock()
    for cursor in editor.getCursors()
      break unless range = @lastPastedRange[cursor.id]
      @setText cursor, range, text

    @unLock()
    # @dump()

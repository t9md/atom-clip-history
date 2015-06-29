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
      # 'clip-history:dump':      => @dump()

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

  tab2space: (s, tabLength) ->
    s.replace /^[\t ]+/, (s) ->
      s.replace /\t/g, _.multiplyString(' ', tabLength)

  space2tab: (s, tabLength) ->
    ms = _.multiplyString
    s.replace /^ +/, (s) ->
      tabs   = ms '\t', Math.floor(s.length / tabLength)
      spaces = ms ' ', (s.length % tabLength)
      tabs + spaces

  getIndent: (editor, point) ->
    leadingText = editor.lineTextForBufferRow(point.row)[0...point.column]
    softTab = _.multiplyString ' ', editor.getTabLength()
    _.multiplyString ' ', leadingText.replace(/\t/g, softTab).length

  adjustIndent: (s, editor, point) ->
    tabLength = editor.getTabLength()
    lines     = s.split("\n")
    unless editor.getSoftTabs()
      lines = lines.map (line) => @tab2space line, tabLength

    spaces = _.first(lines).match(/^ +/)?[0] ? ''
    regex = ///^#{spaces}///g

    adjustable = _.all lines, (line) ->
      return true if line is ''
      line.match regex
    return s unless adjustable

    lines = lines.map (line, i) =>
      return line if line is ''
      line = line.replace regex, ''
      return line if i is 0

      line = @getIndent(editor, point) + line
      unless editor.getSoftTabs()
        line = @space2tab line, tabLength
      line

    lines.join("\n")

  setText: (cursor, range, text) ->
    editor = cursor.editor
    if settings.get('adjustIndent')
      text = @adjustIndent(text, editor, range.start)

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

  syncToSystemClipboard: ->
    clipboadText = atom.clipboard.read()
    if clipboadText isnt @history.peekNext()
      @history.add clipboadText

  paste: (options={}) ->
    return unless editor = @getEditor()

    # system's clipboad might be updated in other place.
    @syncToSystemClipboard()

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

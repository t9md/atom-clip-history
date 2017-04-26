module.exports =
  activate: ->
    @atomClipboardWrite = atom.clipboard.write
    atom.clipboard.write = (args...) =>
      @getHistory().add(args...)
      @atomClipboardWrite.call(atom.clipboard, args...)

    @comandsDisposable = atom.commands.add 'atom-text-editor',
      'clip-history:paste': => @getHistory().paste('older')
      'clip-history:paste-newer': => @getHistory().paste('newer')
      'clip-history:paste-last': => @getHistory().paste('lastPasted')
      'clip-history:clear': => @history?.clear()

  deactivate: ->
    atom.clipboard.write = @atomClipboardWrite
    @history?.destroy()
    @comandsDisposable.dispose()
    [@history, @comandsDisposable] = []

  getHistory: ->
    @history ?= new (require('./history'))

_ = require 'underscore-plus'

describe "clip-history", ->
  getMain = ->
    atom.packages.getLoadedPackage('clip-history').mainModule

  getHistory = ->
    getMain().history

  getEntries = ->
    getHistory().entries

  getCommander = (element) ->
    execute: (command) ->
      atom.commands.dispatch element, command

  getTextsOfEntries = ->
    _.pluck(getEntries(), 'text')

  describe "activation", ->
    beforeEach ->
      waitsForPromise ->
        atom.packages.activatePackage('clip-history')

    describe "when activated", ->
      it "history entries is empty", ->
        expect(getEntries()).toHaveLength 0

      it "wrap original atom.clipboard with new one", ->
        expect(getMain().atomClipboardWrite).not.toEqual(atom.clipboard.write)

    describe "when deactivated", ->
      it "restore original atom.clipboard", ->
        atom.packages.deactivatePackage 'clip-history'
        expect(getMain().atomClipboardWrite).toEqual(atom.clipboard.write)

  describe "history", ->
    [history, commander, main, workspaceElement, editor, editorElement] = []

    beforeEach ->
      atom.config.set('clip-history.max', 3)
      waitsForPromise ->
        atom.packages.activatePackage 'clip-history'

    afterEach ->
      atom.packages.deactivatePackage 'clip-history'

    describe "when new entry added", ->
      it "add new entry", ->
        atom.clipboard.write('one')
        expect(getHistory().entries).toHaveLength 1

        atom.clipboard.write('two')
        expect(getHistory().entries).toHaveLength 2

    describe "when entries exceed max", ->
      data = [ "one", "two", "three" ]
      beforeEach ->
        workspaceElement = atom.views.getView(atom.workspace)
        commander = getCommander workspaceElement

      it "only keep number of entries specified with max", ->
        atom.clipboard.write text for text in data
        expect(getEntries()).toHaveLength 3
        atom.clipboard.write 'four'
        expect(getEntries()).toHaveLength 3

      it "clear entries", ->
        atom.clipboard.write text for text in data
        expect(getEntries()).toHaveLength 3
        commander.execute 'clip-history:clear'
        expect(getEntries()).toHaveLength 0

      it "delete older entries with LILO manner", ->
        atom.clipboard.write text for text in data
        expect(getTextsOfEntries()).toEqual data.slice().reverse()
        expect(getEntries()).toHaveLength 3

        atom.clipboard.write 'four'
        expect(getTextsOfEntries()).toEqual ["four", "three", "two"]

  describe "paste", ->
    [editorCommander, workspaceCommander, editor] = []

    beforeEach ->
      atom.config.set('clip-history.max', 3)
      activationPromise = atom.packages.activatePackage('clip-history')
      samplePath        = atom.project.getDirectories()[0].resolve("sample.txt")

      waitsForPromise ->
        activationPromise
        atom.workspace.open(samplePath).then (_editor) ->
          editor          = _editor
          editorCommander = getCommander atom.views.getView(_editor)
      workspaceCommander = getCommander atom.views.getView(atom.workspace)

    moveTo = (point) ->
      editor.setCursorBufferPosition point

    selectWordsUnderCursors = ->
      editor.selectWordsContainingCursors()

    getWordUnderCursor = ->
      editor.getWordUnderCursor()

    afterEach ->
      atom.packages.deactivatePackage 'clip-history'

    describe 'paste', ->
      it 'paste older entries each time it executed', ->
        points = [[0, 0], [1, 0], [2, 0]]
        for point in points
          moveTo point
          selectWordsUnderCursors()
          editorCommander.execute 'core:copy'

        data = ['three', 'two', 'one']
        expect(getTextsOfEntries()).toEqual data

        moveTo [5, 0]
        for text in [data..., data...]
          workspaceCommander.execute 'clip-history:paste'
          expect(getWordUnderCursor()).toEqual text

  # describe 'adjustIndent', ->
  #   beforeEach ->
  #     activationPromise = atom.packages.activatePackage('clip-history')
  #     waitsForPromise ->
  #       activationPromise
  #
  #   it 'adjust indent', ->
  #     indent = ' '.repeat(10)
  #     s1  = "  two space indent\n"
  #     s1 += "     level-2\n"
  #     s1 += "\n"
  #     s1 += "       level-3\n"
  #
  #     s2  = "two space indent\n"
  #     s2 += "#{indent}   level-2\n"
  #     s2 += "\n"
  #     s2 += "#{indent}     level-3\n"
  #     expect(getMain().adjustIndent(s1, indent)).toEqual s2
  #
  #   it "won't adjust if there is shallow indent than first line", ->
  #     indent = ' '.repeat(10)
  #     s1  = "  two space indent\n"
  #     s1 += "\n"
  #     s1 += " shallow\n"
  #     s1 += "       level-3\n"
  #     expect(getMain().adjustIndent(s1, indent)).toEqual s1

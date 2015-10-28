_ = require 'underscore-plus'

getMain = ->
  atom.packages.getLoadedPackage('clip-history').mainModule

getHistory = ->
  getMain().history

getCommander = (element) ->
  execute: (command) ->
    atom.commands.dispatch element, command

getTextsOfEntries = ->
  _.pluck(getEntries(), 'text')

describe "clip-history", ->
  [editor, editorElement, main, pathSample, workspaceElement, atomClipboardWrite] = []
  getEntries = ->
    main.history.entries

  getTexts = ->
    _.pluck(getEntries(), 'text')

  dispatchCommand = (element, command) ->
    atom.commands.dispatch element, command

  beforeEach ->
    atom.config.set('clip-history.max', 3)
    # addCustomMatchers(this)
    atomClipboardWrite = atom.clipboard.write

    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise ->
      atom.packages.activatePackage("clip-history").then (pack) ->
        main = pack.mainModule

    samplePath = atom.project.resolvePath("sample.txt")
    waitsForPromise ->
      atom.workspace.open(samplePath).then (e) ->
        editor = e
        editorElement = atom.views.getView(editor)

  describe "initialState", ->
    describe "when activated", ->
      it "history entries is empty", ->
        expect(getEntries()).toHaveLength 0

      it "replace original atom.clipboard.write", ->
        expect(atomClipboardWrite).not.toBe(atom.clipboard.write)

    describe "when deactivated", ->
      it "restore original atom.clipboard.write", ->
        atom.packages.deactivatePackage 'clip-history'
        expect(atom.clipboard.write).toBe(atomClipboardWrite)

  describe "when new entry added", ->
    it "add new entry", ->
      atom.clipboard.write('one')
      expect(getTexts()).toEqual ['one']
      atom.clipboard.write('two')
      expect(getTexts()).toEqual ['two', 'one']

  describe "when entries exceed max", ->
    data = [ "one", "two", "three" ]
    beforeEach ->
      atom.clipboard.write(text) for text in data
      expect(getTexts()).toEqual ['three', 'two', 'one']

    it "remove old entry with FIFO manner", ->
      atom.clipboard.write 'four'
      expect(getTexts()).toEqual ['four', 'three', 'two']

  describe "clip-history:clear", ->
    beforeEach ->
      data = [ "one", "two", "three" ]
      atom.clipboard.write(text) for text in data
      expect(getTexts()).toEqual ['three', 'two', 'one']

    it "clear entries", ->
      dispatchCommand(editorElement, 'clip-history:clear')
      expect(getTexts()).toEqual []

  describe "clip-history:paste", ->
    setPosition = (point) ->
      editor.setCursorBufferPosition point

    describe 'paste', ->
      it 'paste older entry on each execution', ->
        for point in [[0, 0], [1, 0], [2, 0]]
          setPosition(point)
          editor.selectWordsContainingCursors()
          dispatchCommand(editorElement, 'core:copy')

        data = ['three', 'two', 'one']
        expect(getTexts()).toEqual data

        setPosition [5, 0]
        for text in [data..., data...]
          dispatchCommand(editorElement, 'clip-history:paste')
          expect(editor.getWordUnderCursor()).toEqual text

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

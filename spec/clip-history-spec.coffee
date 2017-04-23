describe "clip-history", ->
  [editor, editorElement, main, workspaceElement, atomClipboardWrite] = []
  [pathSample1, pathSample2] = []
  getEntries = ->
    main.history.entries

  getTexts = ->
    getEntries().map((e) -> e.text)

  dispatchCommand = (target, command) ->
    atom.commands.dispatch target, command

  beforeEach ->
    atom.config.set('clip-history.max', 3)
    atomClipboardWrite = atom.clipboard.write
    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise ->
      atom.packages.activatePackage("clip-history").then (pack) ->
        main = pack.mainModule

    pathSample1 = atom.project.resolvePath("sample-1.txt")
    pathSample2 = atom.project.resolvePath("sample-2.txt")
    waitsForPromise ->
      atom.workspace.open(pathSample1).then (e) ->
        editor = e
        editorElement = atom.views.getView(editor)

  describe "activate/dieactivate", ->
    describe "when activated", ->
      it "history is not defined", ->
        expect(main.history).not.toBeDefined()

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

    it "keep latest entry, remove old entry with FIFO manner", ->
      atom.clipboard.write 'four'
      expect(getTexts()).toEqual ['four', 'three', 'two']

    it "can clear entries", ->
      dispatchCommand(editorElement, 'clip-history:clear')
      expect(getTexts()).toEqual([])

  describe "clip-history:paste", ->
    describe 'paste', ->
      it 'paste older entry on each execution', ->
        for point in [[0, 0], [1, 0], [2, 0]]
          editor.setCursorBufferPosition(point)
          editor.selectWordsContainingCursors()
          dispatchCommand(editorElement, 'core:copy')

        data = ['three', 'two', 'one']
        expect(getTexts()).toEqual data

        editor.setCursorBufferPosition([5, 0])
        for text in [data..., data...]
          dispatchCommand(editorElement, 'clip-history:paste')
          expect(editor.getWordUnderCursor()).toEqual(text)

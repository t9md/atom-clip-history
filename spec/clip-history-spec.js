describe("clip-history", () => {
  let editor, main, workspaceElement, atomClipboardWrite
  const getHistoryTexts = () => main.history.entries.map(e => e.text)
  const dispatch = (target, command) => atom.commands.dispatch(target, command)

  beforeEach(() => {
    atom.config.set("clip-history.max", 3)
    atomClipboardWrite = atom.clipboard.write
    workspaceElement = atom.views.getView(atom.workspace)
    waitsForPromise(async () => {
      const pack = await atom.packages.activatePackage("clip-history")
      main = pack.mainModule
    })

    const sampleText = ["one", "two", "three", "four", "", "", "", "", "", "ten"].join("\n")
    waitsForPromise(async () => {
      editor = await atom.workspace.open()
      editor.setText(sampleText)
    })
  })

  describe("activate/dieactivate", () => {
    describe("when activated", () => {
      it("history is not defined", () => {
        expect(main.history).not.toBeDefined()
      })

      it("replace original atom.clipboard.write", () => {
        expect(atomClipboardWrite).not.toBe(atom.clipboard.write)
      })
    })

    describe("when deactivated", () => {
      it("restore original atom.clipboard.write", () => {
        atom.packages.deactivatePackage("clip-history")
        expect(atom.clipboard.write).toBe(atomClipboardWrite)
      })
    })
  })

  describe("when new entry added", () => {
    it("add new entry", () => {
      atom.clipboard.write("one")
      expect(getHistoryTexts()).toEqual(["one"])
      atom.clipboard.write("two")
      expect(getHistoryTexts()).toEqual(["two", "one"])
    })
  })

  describe("when entries exceed max", () => {
    beforeEach(() => {
      atom.clipboard.write("one")
      atom.clipboard.write("two")
      atom.clipboard.write("three")
      expect(getHistoryTexts()).toEqual(["three", "two", "one"])
    })

    it("keep latest entry, remove old entry with FIFO manner", () => {
      atom.clipboard.write("four")
      expect(getHistoryTexts()).toEqual(["four", "three", "two"])
    })

    it("can clear entries", () => {
      dispatch(editor.element, "clip-history:clear")
      expect(getHistoryTexts()).toEqual([])
    })
  })

  describe("clip-history:paste", () => {
    it("paste older entry on each execution", () => {
      const copyWordAtPoint = point => {
        editor.setCursorBufferPosition(point)
        editor.selectWordsContainingCursors()
        dispatch(editor.element, "core:copy")
      }

      copyWordAtPoint([0, 0])
      copyWordAtPoint([1, 0])
      copyWordAtPoint([2, 0])
      expect(getHistoryTexts()).toEqual(["three", "two", "one"])

      editor.setCursorBufferPosition([5, 0]) // move to empty row
      for (const text of ["three", "two", "one", "three", "two", "one"]) {
        dispatch(editor.element, "clip-history:paste")
        expect(editor.getWordUnderCursor()).toEqual(text)
      }
    })
  })
})

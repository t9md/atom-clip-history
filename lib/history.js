let adjustIndent
const PasteArea = require("./paste-area")

function getConfig(param) {
  return atom.config.get(`clip-history.${param}`)
}

module.exports = class History {
  constructor() {
    this.lastPastedText = null
    this.pasting = false
    this.pasteArea = new PasteArea()
    this.clear()
  }

  clear() {
    this.entries = []
    this.resetIndex()
  }

  resetPasteState() {
    this.pasteArea.clear()
    this.resetIndex()
  }

  resetIndex() {
    this.index = -1
  }

  destroy() {
    this.pasteArea.destroy()
    if (this.cursorMoveObserver) this.cursorMoveObserver.dispose()
  }

  add(text, metadata) {
    // skip when empty or same text
    if (!text.length || text === this.entries[0]) {
      return
    }
    this.entries.unshift({text, metadata})

    // Unique by entry.text
    const entries = []
    const seen = {}
    for (let entry of this.entries) {
      if (entry.text in seen) continue
      entries.push(entry)
      seen[entry.text] = true
    }
    this.entries = entries
    this.entries.splice(getConfig("max"))
    this.resetIndex()
  }

  getEntry(which) {
    const index = this.index + (which === "newer" ? -1 : +1)
    this.index = this.getIndex(index)
    return this.entries[this.index]
  }

  // To make index rap within length
  getIndex(index) {
    const length = this.entries.length
    if (!length) return -1
    index = index % length
    return index >= 0 ? index : length + index
  }

  paste(editor, which) {
    if (editor.hasMultipleCursors() && getConfig("doNormalPasteWhenMultipleCursors")) {
      editor.pasteText()
      return
    }

    if (this.pasteArea.isEmpty()) {
      // This is 1st paste, system's clipboad might updated in outer world.
      this.add(atom.clipboard.read())
    }

    let textToPaste
    if (which === "lastPasted") {
      this.resetPasteState()
      textToPaste = this.lastPastedText
    } else {
      textToPaste = this.getEntry(which)
    }

    if (!textToPaste) return

    this.observeCursorMove(editor)
    this.pasting = true

    for (const cursor of editor.getCursors()) {
      this.insertText(cursor, textToPaste.text)
    }
    editor.scrollToCursorPosition({center: false})
    this.lastPastedText = textToPaste

    this.pasting = false
  }

  insertText(cursor, text) {
    const editor = cursor.editor
    const range = this.pasteArea.has(cursor) ? this.pasteArea.getRange(cursor) : cursor.selection.getBufferRange()
    if (getConfig("adjustIndent") && text.endsWith("\n")) {
      if (!adjustIndent) adjustIndent = require("./adjust-indent")
      text = adjustIndent(text, {editor, indent: " ".repeat(range.start.column)})
    }

    const marker = editor.markBufferRange(editor.setTextInBufferRange(range, text))
    this.pasteArea.set(cursor, marker)

    if (getConfig("flashOnPaste")) {
      const markerForFlash = marker.copy()
      editor.decorateMarker(markerForFlash, {type: "highlight", class: "clip-history-pasted"})
      setTimeout(() => markerForFlash.destroy(), 1000)
    }
  }

  observeCursorMove(editor) {
    if (!this.cursorMoveObserver) {
      this.cursorMoveObserver = editor.onDidChangeCursorPosition(() => {
        if (this.pasting) return
        this.resetPasteState()
        this.cursorMoveObserver.dispose()
        this.cursorMoveObserver = null
      })
    }
  }
}

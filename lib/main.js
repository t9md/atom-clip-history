module.exports = {
  activate() {
    this.atomClipboardWrite = atom.clipboard.write
    atom.clipboard.write = (...args) => {
      this.getHistory().add(...args)
      return this.atomClipboardWrite.call(atom.clipboard, ...args)
    }

    const paste = (editor, which) => this.getHistory().paste(editor, which)

    // prettier-ignore
    this.disposable = atom.commands.add("atom-text-editor", {
      "clip-history:paste"() { paste(this.getModel(), "older") },
      "clip-history:paste-newer"() { paste(this.getModel(), "newer") },
      "clip-history:paste-last"() { paste(this.getModel(), "lastPasted") },
      "clip-history:clear": () => this.history && this.history.clear(),
    })
  },

  deactivate() {
    atom.clipboard.write = this.atomClipboardWrite
    if (this.history) this.history.destroy()
    this.disposable.dispose()
  },

  getHistory() {
    if (!this.history) {
      const History = require("./history")
      this.history = new History()
    }
    return this.history
  },
}

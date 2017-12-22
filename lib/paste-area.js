module.exports = class PasteArea {
  constructor() {
    this.markerByCursor = new Map()
  }

  has(cursor) {
    return this.markerByCursor.has(cursor)
  }

  getRange(cursor) {
    if (this.has(cursor)) {
      return this.markerByCursor.get(cursor).getBufferRange()
    }
  }

  set(cursor, marker) {
    if (this.has(cursor)) {
      this.markerByCursor.get(cursor).destroy()
    }
    this.markerByCursor.set(cursor, marker)
  }

  clear() {
    this.markerByCursor.forEach(marker => marker.destroy())
    this.markerByCursor.clear()
  }

  isEmpty() {
    return this.markerByCursor.size === 0
  }

  destroy() {
    this.clear()
  }
}

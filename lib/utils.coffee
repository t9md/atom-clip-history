_ = require 'underscore-plus'

getEditor = ->
  atom.workspace.getActiveTextEditor()

tab2space = (s, tabLength) ->
  s.replace /^[\t ]+/, (s) ->
    s.replace /\t/g, _.multiplyString(' ', tabLength)

space2tab = (s, tabLength) ->
  s.replace /^ +/, (s) ->
    tabs   = _.multiplyString '\t', Math.floor(s.length / tabLength)
    spaces = _.multiplyString ' ', (s.length % tabLength)
    tabs + spaces

getIndent = (editor, point) ->
  leadingText = editor.lineTextForBufferRow(point.row)[0...point.column]
  softTab = _.multiplyString ' ', editor.getTabLength()
  _.multiplyString ' ', leadingText.replace(/\t/g, softTab).length

adjustIndent = (s, editor, point) ->
  tabLength = editor.getTabLength()
  lines     = s.split("\n")
  unless editor.getSoftTabs()
    lines = lines.map (line) -> tab2space line, tabLength

  spaces = _.first(lines).match(/^ +/)?[0] ? ''
  regex = ///^#{spaces}///g

  adjustable = _.all lines, (line) ->
    return true if line is ''
    line.match regex
  return s unless adjustable

  lines = lines.map (line, i) ->
    return line if line is ''
    line = line.replace regex, ''
    return line if i is 0

    line = getIndent(editor, point) + line
    unless editor.getSoftTabs()
      line = space2tab line, tabLength
    line
  lines.join("\n")

flash = (editor, marker, options) ->
  {color, duration, persist, class: klass} = options
  marker = marker.copy() unless persist?
  editor.decorateMarker marker,
    type: 'highlight'
    class: klass

  unless persist
    setTimeout  ->
      marker.destroy()
    , duration

spyClipBoardWrite = (fn) ->
  atomClipboardWrite = atom.clipboard.write
  atom.clipboard.write = (params...) ->
    fn(params...)
    atomClipboardWrite.call(atom.clipboard, params...)
  ->
    atom.clipboard.write = atomClipboardWrite

module.exports = {
  getEditor, tab2space, space2tab, getIndent, adjustIndent, flash, spyClipBoardWrite
}

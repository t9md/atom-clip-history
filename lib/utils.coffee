_ = require 'underscore-plus'

tab2space = (s, tabLength) ->
  s.replace /^[\t ]+/, (s) ->
    s.replace /\t/g, _.multiplyString(' ', tabLength)

space2tab = (text, tabLength) ->
  text.replace /^ +/, (s) ->
    tabs   = _.multiplyString '\t', Math.floor(s.length / tabLength)
    spaces = _.multiplyString ' ', (s.length % tabLength)
    tabs + spaces

getIndentText = (editor, {row, column}) ->
  leadingText = editor.lineTextForBufferRow(row)[0...column]
  softTab = _.multiplyString ' ', editor.getTabLength()
  _.multiplyString ' ', leadingText.replace(/\t/g, softTab).length

isEmptyOrMatch = (text, pattern) ->
  (text is '') or text.match(pattern)

adjustIndent = (editor, text, point) ->
  tabLength = editor.getTabLength()
  lines = text.split("\n")
  isHardTabs = not editor.getSoftTabs()
  if isHardTabs
    lines = lines.map((line) -> tab2space(line, tabLength))

  spaces = _.first(lines).match(/^ +/)?[0] ? ''
  regexp = ///^#{spaces}///g

  unless _.all(lines, (l) -> isEmptyOrMatch(l, regexp))
    return text

  indent = getIndentText(editor, point)
  lines = lines.map (line) -> line.replace(regexp, '')
  lines = lines.map (line, i) ->
    if (i is 0) or line is ''
      line
    else
      line = indent + line
      if isHardTabs
        space2tab(line, tabLength)
      else
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


# Return function to restore original function.
spyClipBoardWrite = (fn) ->
  atomClipboardWrite = atom.clipboard.write
  atom.clipboard.write = (params...) ->
    fn(params...)
    atomClipboardWrite.call(atom.clipboard, params...)
  ->
    atom.clipboard.write = atomClipboardWrite

module.exports = {adjustIndent, flash, spyClipBoardWrite}

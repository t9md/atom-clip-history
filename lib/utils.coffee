_ = require 'underscore-plus'

# Convert leading tab to space. support multiline string.
tab2space = (text, tabLength) ->
  text.replace /^[\t ]+/gm, (text) ->
    text.replace /\t/g, _.multiplyString(' ', tabLength)

# Convert leading space to tab. support multiline string.
space2tab = (text, tabLength) ->
  text.replace /^ +/gm, (s) ->
    tabs = _.multiplyString '\t', Math.floor(s.length / tabLength)
    spaces = _.multiplyString ' ', (s.length % tabLength)
    tabs + spaces

# Return shortest leading space string in multiline string.
getShortestLeadingSpace = (text) ->
  if text.match(/^[^ ]/gm)
    ''
  else
    spaces = text.match(/^ +/gm)
    _.sortBy(spaces, (e) -> e.length)[0]

removeIndent = (text) ->
  indent = getShortestLeadingSpace(text)
  text.replace(///^#{indent}///gm, '')

addIndent = (text, indent) ->
  text.replace ///^///gm, (m, offset) ->
    if offset is 0 then m else indent

adjustIndent = (text, {indent, softTabs, tabLength}) ->
  text = tab2space(text, tabLength)
  text = removeIndent(text)
  text = addIndent(text, indent)
  if softTabs
    text
  else
    space2tab(text, tabLength)

flash = (editor, marker, options) ->
  {color, duration, persist, class: klass} = options
  marker = marker.copy() unless persist
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

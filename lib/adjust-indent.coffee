# Convert leading tab to space. support multiline string.
tab2space = (text, tabLength) ->
  text.replace /^[\t ]+/gm, (text) ->
    text.replace(/\t/g, ' '.repeat(tabLength))

# Convert leading space to tab. support multiline string.
space2tab = (text, tabLength) ->
  text.replace /^ +/gm, (s) ->
    tabs = '\t'.repeat(Math.floor(s.length / tabLength))
    spaces = ' '.repeat(s.length % tabLength)
    tabs + spaces

# Return shortest leading space string in multiline string.
getShortestLeadingSpace = (text) ->
  if text.match(/^[^ ]/gm)
    ''
  else
    text.match(/^ +/gm).sort((a, b) -> a.length - b.length)[0]

removeIndent = (text) ->
  indent = getShortestLeadingSpace(text)
  text.replace(///^#{indent}///gm, '')

addIndent = (text, indent) ->
  text.replace /^/gm, (m, offset) ->
    if offset is 0 then m else indent

module.exports = adjustIndent = (text, {editor, indent}) ->
  softTabs = editor.getSoftTabs()
  tabLength = editor.getTabLength()

  text = tab2space(text, tabLength)
  text = removeIndent(text)
  text = addIndent(text, indent)
  if softTabs
    text
  else
    space2tab(text, tabLength)

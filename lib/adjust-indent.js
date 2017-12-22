// Convert leading tab to space. support multiline string.
function tab2space(text, tabLength) {
  return text.replace(/^[\t ]+/gm, text => {
    return text.replace(/\t/g, " ".repeat(tabLength))
  })
}

// Convert leading space to tab. support multiline string.
function space2tab(text, tabLength) {
  return text.replace(/^ +/gm, function(s) {
    const tabs = "\t".repeat(Math.floor(s.length / tabLength))
    const spaces = " ".repeat(s.length % tabLength)
    return tabs + spaces
  })
}

// Return shortest leading space string in multiline string.
function getShortestLeadingSpace(text) {
  if (text.match(/^[^ ]/gm)) {
    return ""
  } else {
    return text.match(/^ +/gm).sort((a, b) => a.length - b.length)[0]
  }
}

function removeIndent(text) {
  const indent = getShortestLeadingSpace(text)
  return text.replace(new RegExp(`^${indent}`, "gm"), "")
}

function addIndent(text, indent) {
  return text.replace(/^/gm, (m, offset) => (offset === 0 ? m : indent))
}

function adjustIndent(text, {editor, indent}) {
  const tabLength = editor.getTabLength()
  text = tab2space(text, tabLength)
  text = removeIndent(text)
  text = addIndent(text, indent)
  return editor.getSoftTabs() ? text : space2tab(text, tabLength)
}

module.exports = adjustIndent

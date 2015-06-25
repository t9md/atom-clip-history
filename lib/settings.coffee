ConfigPlus = require 'atom-config-plus'

config =
  max:
    order: 11
    type: 'integer'
    default: 10
    minimum: 1
    description: "Number of history to remember"
  flashOnPaste:
    order: 21
    type: 'boolean'
    default: true
    description: "Flash when pasted"
  flashPersist:
    order: 22
    type: 'boolean'
    default: false
    description: "Flash persisted"
  flashDurationMilliSeconds:
    order: 23
    type: 'integer'
    default: 300
    description: "Duration for flash"
  flashColor:
    order: 24
    type: 'string'
    default: 'highlight'
    enum: ['info', 'success', 'warning', 'error', 'highlight', 'selected']
    description: 'Flash color. Correspoinding to @background-color-#{flashColor}: see `styleguide:show`'
  adjustIndent:
    order: 25
    type: 'boolean'
    default: true
    description: "Adjust indentation when pasted."

module.exports = new ConfigPlus('clip-history', config)

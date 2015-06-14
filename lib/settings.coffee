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
  flashDurationMilliSeconds:
    order: 22
    type: 'integer'
    default: 300
    description: "Duration for flash"

module.exports = new ConfigPlus('clip-history', config)

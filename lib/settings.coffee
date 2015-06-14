ConfigPlus = require 'atom-config-plus'

config =
  max:
    order: 11
    type: 'integer'
    default: 100
    minimum: 1
    description: "number of history to remember"
  flashOnPaste:
    order: 21
    type: 'boolean'
    default: true
    description: "flash when pasted"
  flashDurationMilliSeconds:
    order: 22
    type: 'integer'
    default: 300
    description: "Duration for flash"

module.exports = new ConfigPlus('clip-history', config)

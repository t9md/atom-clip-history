_ = require 'underscore-plus'
class Settings
  constructor: (@scope, @config) ->

  notifyOldParamsAndDelete: ->
    paramsSupported = _.keys(@config)
    paramsCurrent = _.keys(atom.config.get(@scope))
    paramsToDelete = _.difference(paramsCurrent, paramsSupported)
    return if paramsToDelete.length is 0
    @delete(param) for param in paramsToDelete

    deletedParamsText = ("- #{param}" for param in paramsToDelete).join("\n")
    message = """
      #{@scope}: Following configs are no longer supported.__
      Automatically removed from your `connfig.cson`__
      #{deletedParamsText}
      """.replace(/_/g, " ")
    atom.notifications.addWarning(message, dismissable: true)

  has: (param) ->
    param of atom.config.get(@scope)

  delete: (param) ->
    @set(param, undefined)

  get: (param) ->
    atom.config.get "#{@scope}.#{param}"

  set: (param, value) ->
    atom.config.set "#{@scope}.#{param}", value

module.exports = new Settings 'clip-history',
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
    order: 23
    type: 'integer'
    default: 300
    description: "Duration for flash"
  adjustIndent:
    order: 25
    type: 'boolean'
    default: true
    description: "Keep layout of pasted text by adjusting indentation."
  doNormalPasteWhenMultipleCursors:
    order: 26
    type: 'boolean'
    default: true
    description: "Keep layout of pasted text by adjusting indentation."

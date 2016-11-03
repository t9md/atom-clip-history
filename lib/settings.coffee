_ = require 'underscore-plus'
class Settings
  constructor: (@scope, @config) ->
    # Inject order props to display orderd in setting-view
    for name, i in Object.keys(@config)
      @config[name].order = i

    # Automatically infer and inject `type` of each config parameter.
    for key, object of @config
      object.type = switch
        when Number.isInteger(object.default) then 'integer'
        when typeof(object.default) is 'boolean' then 'boolean'
        when typeof(object.default) is 'string' then 'string'
        when Array.isArray(object.default) then 'array'

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
    default: 10
    minimum: 1
    description: "Number of history to remember"
  flashOnPaste:
    default: true
    description: "Flash when pasted"
  flashDurationMilliSeconds:
    default: 300
    description: "Duration for flash"
  adjustIndent:
    default: true
    description: "Keep layout of pasted text by adjusting indentation."
  doNormalPasteWhenMultipleCursors:
    default: true
    description: "Keep layout of pasted text by adjusting indentation."

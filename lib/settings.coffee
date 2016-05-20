class Settings
  constructor: (@scope, @config) ->

  get: (param) ->
    if param is 'defaultRegister'
      if @get('useClipboardAsDefaultRegister') then '*' else '"'
    else
      atom.config.get "#{@scope}.#{param}"

  set: (param, value) ->
    atom.config.set "#{@scope}.#{param}", value

  toggle: (param) ->
    @set(param, not @get(param))

  observe: (param, fn) ->
    atom.config.observe "#{@scope}.#{param}", fn

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
  adjustIndent:
    order: 25
    type: 'boolean'
    default: true
    description: "Keep layout of pasted text by adjusting indentation."

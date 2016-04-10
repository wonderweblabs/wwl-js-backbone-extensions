_ = require('underscore')

module.exports = class AbstractCollection extends require('backbone').Collection

  # The context instance set in constructor
  context: null

  # Json root name for server communication. The abstract implementation
  # expects transfered data to be nested inside rootName. You can disable
  # that behavior by setting syncWithoutRoot: false
  #
  # e.g. { data: [{ id: 1, name: 'Article 1' }] }
  rootName: 'data'

  # Don't include rootName-root to json when sending data to the server.
  syncWithoutRoot: false

  # @constructor
  constructor: (attributes, options = {}) ->
    @options = options || {}
    @context = options.context

    if _.isString(@getOption('rootName')) == false || @getOption('rootName').length <= 0
      throw new Error('AbstractCollection: must have a valid rootName string.')

    if _.isUndefined(@context) || _.isNull(@context)
      throw new Error('AbstractCollection: must have an context object')

    super attributes, options

  # Returns the value for the passed optionName name, either defined on the
  # passed options object or on the prototype.
  getOption: (optionName) ->
    return unless optionName

    if @options && !_.isUndefined(@options[optionName])
      _.result(@options, optionName)
    else
      _.result(@, optionName)

  # The meta data object.
  getMeta: ->
    @_meta or= {}

  # Overwrite that function!
  #
  # You can manipulate the url used for server communications here.
  # This might be useful for example, if you want to add a subpath
  # or a full qualified host for your urls.
  prependedUrl: ->
    @getOption('url')

  # You might want to you toJSON for other things than syncing to the
  # server. That's why abstract uses toSyncJSON to build data
  # for server communications.
  toSyncJSON: (options = {}) ->
    data = @toJSON(options)

    withoutRoot = options.withoutRoot
    withoutRoot = @getOption('syncWithoutRoot') if withoutRoot != true

    if withoutRoot == true then data else { "#{@getOption('rootName')}": data }


  # ---------------------------------------------
  # private methods

  # @nodoc
  _prepareModel: (attrs, options = {}) =>
    options.context = @getOption('context')

    super(attrs, options)
_ = require('underscore')

module.exports = class Abstract extends require('backbone').Model

  # The context instance set in constructor
  context: null

  # Json root name for server communication. The abstract implementation
  # expects transfered data to be nested inside rootName. You can disable
  # that behavior by setting syncWithoutRoot: false
  #
  # e.g. { data: { id: 1, name: 'Article 1' } }
  rootName: 'data'

  # Attributes that will be omitted when sending to server
  # It works in combination with jsonOmitted.
  jsonOmitted: []

  # Attributes that will be picked when sending to the server.
  # It works in combination with jsonPermitted.
  jsonPermitted: []

  # Don't include rootName-root to json when sending data to the server.
  syncWithoutRoot: false

  # When set to true, the model ensures to set an id after creatign the
  # instance by using the #getRandomBinaryId method.
  binaryId: false

  # @constructor
  constructor: (attributes, options = {}) ->
    @options        = options || {}
    @context        = options.context
    @_synchronized  = 0
    @_synchronizing = false
    @_idSetByClient = false

    if _.isString(@getOption('rootName')) == false || @getOption('rootName').length <= 0
      throw new Error('AbstractModel: must have a valid rootName string.')

    if _.isUndefined(@context) || _.isNull(@context)
      throw new Error('AbstractModel: must have an context object')

    super attributes, options

    @_ensureBinaryId()

  initialize: (attrs = {}, options = {}) ->
    super(attrs, options)

    @listenTo @getRemoteErrors(), 'all', @onRemoteErrorsAllEvent

  getRootName: ->
    @getOption('rootName')

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
  # When using binaryId: true, this function returns the client side generated
  # id for the current model.
  getRandomBinaryId: ->
    throw new Error('AbstractModel: must implement getRandomBinaryId to return random string')

  # ErrorsCollection (Backbone.Collection) of local errors.
  # Use this collection for local validation.
  getLocalErrors: ->
    @_localErrorsCollection or= new (require('../collections/errors_collection'))()

  # ErrorsCollection (Backbone.Collection) of remote errors.
  # It'll be filled by ajax responses, which include either { data: { errors ... } }
  # and/or { meta: { errors... } } and/or { errors .... }
  getRemoteErrors: ->
    @_remoteErrorsCollection or= new (require('../collections/errors_collection'))()

  # Whether the model has been synced once or more with the server
  isSynced: ->
    @_synchronized > 0

  # Whether the model is currently in sync process or not
  isSyncing: ->
    @_synchronizing || false

  # TODO
  isNew: ->
    super() || (@_idSetByClient == true && !@isSynced())

  # true/false whether @getLocalErrors().areAllValid() is true or not
  isLocalValid: (key = null) ->
    if key
      @getLocalErrors().isValid(key)
    else
      @getLocalErrors().areAllValid()

  # true/false whether @getRemoteErrors().areAllValid() is true or not
  isRemoteValid: (key = null) ->
    if key
      @getRemoteErrors().isValid(key)
    else
      @getRemoteErrors().areAllValid()

  # Overwrite that function!
  #
  # You can manipulate the url used for server communications here.
  # This might be useful for example, if you want to add a subpath
  # or a full qualified host for your urls.
  prependedUrlRoot: (url) ->
    return @getOption('urlRoot') unless _.isString(url)

    ['', url.replace(/^\//, '')].join('/')

  # Unset all attributes except of the id.
  #
  # You can pass { discardId: true } to unset id too.
  unsetAll: (options = {}) ->
    attrs = if options.discardId == true then @attributes else _.omit @attributes, 'id'

    @set attrs, _.extend {}, options, { unset: true }

  # Parses response data.
  #
  # Important: if you need to define custom parsing logic, always call
  # super(..) to ensure the full feature set of abstract.
  parse: (data = {}, options = {}) ->
    @_synchronized += 1 if options._synchronized == true

    data[@getRootName()] or= {}

    extractedData   = data[@getRootName()]
    extractedMeta   = _.omit(data, @getRootName())

    @_parseErrors(extractedData.errors, true)
    @_parseErrors(extractedMeta.errors)
    @_parseErrors(extractedMeta.meta.errors) if extractedMeta.meta

    extractedData       = _.omit(extractedData, 'errors')
    extractedMeta       = _.omit(extractedMeta, 'errors')
    extractedMeta.meta  = _.omit(extractedMeta.meta, 'errors') if extractedMeta.meta

    super extractedData, options

  # You might want to you toJSON for other things than syncing to the
  # server. That's why abstract uses toSyncJSON to build data
  # for server communications.
  #
  # toSyncJSON uses toJSON and filters it with filterJSON
  toSyncJSON: (options = {}) ->
    data = @filterJSON(@toJSON(options))

    withoutRoot = options.withoutRoot
    withoutRoot = @getOption('syncWithoutRoot') if withoutRoot != true

    if withoutRoot == true then data else { "#{@getRootName()}": data }

  # Filters passed data with
  # 1. filterPermittedJSON
  # 2. filterOmittedJSON
  filterJSON: (json = {}) ->
    @filterOmittedJSON(@filterPermittedJSON(json))

  # Filters passed data with _.pick for jsonPermitted
  filterPermittedJSON: (json = {}) ->
    return json unless _.isArray(@getOption('jsonPermitted'))
    return json unless _.any(@getOption('jsonPermitted'))

    _.pick json, @getOption('jsonPermitted')

  # Filters passed data with _.omit for jsonOmitted
  filterOmittedJSON: (json = {}) ->
    return json unless _.isArray(@getOption('jsonOmitted'))
    return json unless _.any(@getOption('jsonOmitted'))

    _.omit json, @getOption('jsonOmitted')

  # Adds before:save event to the model
  save: (key, val, options) ->
    @trigger 'before:save', @, key, val, options

    super(key, val, options)

  # Overwriting and append each sync call
  sync: (method, model, options = {}) ->
    @_syncPrepare method, model, options

    super method, model, options

  # @private
  onRemoteErrorsAllEvent: =>
    args  = Array.prototype.slice.call(arguments)
    event = args.shift()

    args.unshift("remoteErrors:#{event}")
    @trigger.apply(@, args)

    args.unshift("remoteErrors:all")
    @trigger.apply(@, args)


  # ---------------------------------------------
  # private methods

  # @nodoc
  _ensureBinaryId: ->
    return unless @getOption('binaryId') == true
    return if @has(@idAttribute) && _.isString(@get(@idAttribute)) && @get(@idAttribute).length > 0

    @id = @getRandomBinaryId()
    @set('id', @id, { silent: true })

    @_idSetByClient = true

  # @nodoc
  _parseErrors: (errorsHash, reset = false) ->
    @getRemoteErrors().reset([]) if reset == true

    return unless _.isObject(errorsHash)

    _.each errorsHash, (v, k) =>
      @getRemoteErrors().add { id: k, errors: v }, { merge: true }

  # @nodoc
  _syncPrepare: (method, model, options) ->
    @_synchronizing = true
    @trigger 'beforeSync', method, model, options

    options.url or= @prependedUrlRoot(_.result(@, 'url'))

    options.attrs = @toSyncJSON(options) unless options['attrs']

    originalSuccess     = options.success
    originalError       = options.error
    unsetOnSync         = options.unsetOnSync

    options.success = (responseData, resp, options = {}) =>
      @_idSetByClient = false
      @unsetAll() if unsetOnSync == true
      @_syncAlways responseData, resp, options, originalSuccess

    options.error   = (responseData, resp, options = {}) =>
      @_syncAlways responseData, resp, options, originalError

  # @nodoc
  _syncAlways: (responseData, resp, options, callback = null) =>
    @_synchronized += 1
    @_synchronizing = false

    callback(responseData, resp, options) if _.isFunction(callback)

    @unset 'errors', { silent: true }



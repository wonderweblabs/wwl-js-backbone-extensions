_ = require('underscore')

module.exports = class Abstract extends require('backbone').Model

  context: null

  rootName: 'data'

  jsonOmitted: []

  jsonPermitted: []

  syncWithoutRoot: false

  binaryId: false

  _idSetByClient: false

  constructor: (attributes, options = {}) ->
    @options        = options || {}
    @context        = options.context
    @_synchronized  = 0

    if _.isString(@getOption('rootName')) == false || @getOption('rootName').length <= 0
      throw new Error('AbstractModel: must have a valid rootName string.')

    if _.isUndefined(@context) || _.isNull(@context)
      throw new Error('AbstractModel: must have an context object')

    super attributes, options

    @_ensureBinaryId()

  getOption: (optionName) ->
    return unless optionName

    if @options && !_.isUndefined(@options[optionName])
      _.result(@options, optionName)
    else
      _.result(@, optionName)

  getMeta: ->
    @_meta or= {}

  getRandomBinaryId: ->
    throw new Error('AbstractModel: must implement getRandomBinaryId to return random string')

  getLocalErrors: ->
    @_localErrorsCollection or= new (require('../collections/errors_collection'))()

  getRemoteErrors: ->
    @_remoteErrorsCollection or= new (require('../collections/errors_collection'))()

  isSynced: ->
    @_synchronized > 0

  isNew: ->
    super() || (@_idSetByClient == true && !@isSynced())

  isLocalValid: (key = null) ->
    if key
      @getLocalErrors().isValid(key)
    else
      @getLocalErrors().areAllValid()

  isRemoteValid: (key = null) ->
    if key
      @getRemoteErrors().isValid(key)
    else
      @getRemoteErrors().areAllValid()

  prependedUrlRoot: ->
    @getOption('urlRoot')

  unsetAll: (options = {}) ->
    attrs = if options.discardId == true then @attributes else _.omit @attributes, 'id'

    @set attrs, _.extend {}, options, { unset: true }

  parse: (data, options = {}) ->
    @_synchronized += 1 if options._synchronized == true

    extractedData   = data[@getOption('rootName')]
    extractedMeta   = _.omit(data, @getOption('rootName'))

    @_parseErrors(extractedData.errors, true)
    @_parseErrors(extractedMeta.errors)
    @_parseErrors(extractedMeta.meta.errors) if extractedMeta.meta

    extractedData       = _.omit(extractedData, 'errors')
    extractedMeta       = _.omit(extractedMeta, 'errors')
    extractedMeta.meta  = _.omit(extractedMeta.meta, 'errors') if extractedMeta.meta

    super extractedData, options

  toSyncJSON: (options = {}) ->
    data = @filterJSON(@toJSON(options))

    withoutRoot = options.withoutRoot
    withoutRoot = @getOption('syncWithoutRoot') if withoutRoot != true

    if withoutRoot == true then data else { "#{@getOption('rootName')}": data }

  filterJSON: (json = {}) ->
    @filterOmittedJSON(@filterPermittedJSON(json))

  filterPermittedJSON: (json = {}) ->
    return json unless _.isArray(@getOption('jsonPermitted'))
    return json unless _.any(@getOption('jsonPermitted'))

    _.pick json, @getOption('jsonPermitted')

  filterOmittedJSON: (json = {}) ->
    return json unless _.isArray(@getOption('jsonOmitted'))
    return json unless _.any(@getOption('jsonOmitted'))

    _.omit json, @getOption('jsonOmitted')


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




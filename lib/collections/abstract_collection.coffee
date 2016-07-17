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
    @options        = options || {}
    @context        = options.context
    @_synchronized  = 0
    @_synchronizing = false

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

  # More failsafe way to load objects
  get: (obj) ->
    if _.isObject(obj) && _.isObject(obj.data) then super(obj.data) else super(obj)

  # Returns { model: ..model instance.. } if the model for the passed id is already
  # listed inside the collection.
  #
  # If not, it'll create it by id and directly fetch it from the server. You'll get
  # { model: ..model instance.., jqxhr: ..jqxhr object.. }.
  #
  # You can pass fetch=true to force loading.
  getOrFetch: (id, attributes = {}, fetch = false) ->
    model       = @get(id)
    attributes  = _.omit attributes, 'id'

    if _.isObject(model)
      model.set attributes
    else
      fetch = true
      model = @_prepareModel(_.extend({}, attributes, { id: id }))

      @set model, { add: true, merge: true, remove: false }

    result = { model: model }
    result.jqxhr = model.fetch() if fetch == true
    result

  # Returns the model instance found by id. If there is no instance for the
  # passed id yet, it'll create it and will return the new one.
  getOrInitialize: (id, attributes = {}, options = {}) ->
    model       = @get(id)
    attributes  = _.omit attributes, 'id'

    if _.isObject(model)
      model.set attributes
    else
      model = @_prepareModel(_.extend({}, attributes, { id: id }), options)

      @set model, { add: true, merge: true, remove: false }

    model

  # Whether the model has been synced once or more with the server
  isSynced: ->
    @_synchronized > 0

  # Whether the model is currently in sync process or not
  isSyncing: ->
    @_synchronizing || false

  # Overwrite that function!
  #
  # You can manipulate the url used for server communications here.
  # This might be useful for example, if you want to add a subpath
  # or a full qualified host for your urls.
  prependedUrlRoot: (url) ->
    return @getOption('url') unless _.isString(url)

    ['', url.replace(/^\//, '')].join('/')

  # You might want to you toJSON for other things than syncing to the
  # server. That's why abstract uses toSyncJSON to build data
  # for server communications.
  toSyncJSON: (options = {}) ->
    data = @toJSON(options)

    withoutRoot = options.withoutRoot
    withoutRoot = @getOption('syncWithoutRoot') if withoutRoot != true

    if withoutRoot == true then data else { "#{@getOption('rootName')}": data }

  # Overwriting and append each sync call
  sync: (method, collection, options) =>
    @_syncPrepare method, collection, options

    super method, collection, options


  # ---------------------------------------------
  # private methods

  # @nodoc
  _prepareModel: (attrs, options = {}) =>
    options.context = @getOption('context')

    super(attrs, options)

  # @nodoc
  _syncPrepare: (method, collection, options) =>
    @_synchronizing = true
    @trigger 'beforeSync', method, collection, options

    originalSuccess = options.success
    originalError   = options.error

    options._synchronized = true

    options.url or= @prependedUrlRoot(_.result(@, 'url'))

    options.success = (responseData, resp, options = {}) =>
      @_syncAlways responseData, resp, options, originalSuccess

    options.error   = (responseData, resp, options = {}) =>
      @_syncAlways responseData, resp, options, originalError

  # @nodoc
  _syncAlways: (responseData, resp, options, callback = null) =>
    @_synchronized += 1
    @_synchronizing = false

    modelsData = []
    _.each responseData.data, (data)->
      modelsData.push({data: data})

    @_meta = responseData['meta'] if responseData['meta']?

    callback(modelsData, resp, options) if _.isFunction(callback)

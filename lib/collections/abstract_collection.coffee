_ = require('underscore')

module.exports = class AbstractCollection extends require('backbone').Collection

  context: null

  rootName: 'data'

  syncWithoutRoot: false

  constructor: (attributes, options = {}) ->
    @options = options || {}
    @context = options.context

    if _.isString(@getOption('rootName')) == false || @getOption('rootName').length <= 0
      throw new Error('AbstractCollection: must have a valid rootName string.')

    if _.isUndefined(@context) || _.isNull(@context)
      throw new Error('AbstractCollection: must have an context object')

    super attributes, options

  getOption: (optionName) ->
    return unless optionName

    if @options && !_.isUndefined(@options[optionName])
      _.result(@options, optionName)
    else
      _.result(@, optionName)

  getMeta: ->
    @_meta or= {}

  prependedUrl: ->
    @getOption('url')

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
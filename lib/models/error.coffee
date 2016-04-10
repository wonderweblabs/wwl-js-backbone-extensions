_ = require('underscore')

module.exports = class Error extends require('backbone').Model

  defaults:
    id:     null
    errors: null

  constructor: (attrs = {}, options = {}) ->
    attrs.errors or= []
    attrs.errors = [attrs.errors] unless _.isArray(attrs.errors)

    if _.isNull(attrs.id) || _.isUndefined(attrs.id)
      throw new Error('Error: must have a valid id attribute.')

    super(attrs, options)

  sync: ->
    false

  isValid: ->
    return true unless @has('errors')
    return true unless _.isArray @get('errors')

    _.any(@get('errors')) == false

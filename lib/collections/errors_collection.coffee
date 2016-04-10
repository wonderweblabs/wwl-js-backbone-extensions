_ = require('underscore')

module.exports = class ErrorsCollection extends require('backbone').Collection

  model: require('../models/error')

  sync: ->
    null

  isValid: (key) ->
    return true unless @get(key)

    @get(key).isValid()

  areAllValid: ->
    return true if @size() <= 0

    @every (error) => error.isValid()

  getMessages: ->
    return [] if @areAllValid()

    _.flatten(@map((e) -> e.get('errors')))

module.exports = class SimpleModel extends require('../../lib/models/abstract')

  getRandomBinaryId: ->
    "#{Math.random()}"
expect  = require('chai').expect
jsdom   = require('mocha-jsdom')
Q       = require('q')

describe 'models/error', ->

  ErrorModel = require('../../lib/models/error')


  # ------------------------------------------------------------------
  describe '#constructor', ->

    it 'should throw error for missing id', ->
      expect(-> new ErrorModel()).to.throw()

    it 'should set empty array as default for errors', ->
      e = new ErrorModel({ id: 'myField' })
      expect(e.get('errors')).to.be.a('array')

  # ------------------------------------------------------------------
  describe '#isValid', ->

    it 'should be true for empty errors array', ->
      e = new ErrorModel({ id: 'myField' })
      expect(e.isValid()).to.be.true
      e = new ErrorModel({ id: 'myField', errors: [] })
      expect(e.isValid()).to.be.true

    it 'should be false for any entry in errors array', ->
      e = new ErrorModel({ id: 'myField', errors: 'my error' })
      expect(e.isValid()).to.be.false
      e = new ErrorModel({ id: 'myField', errors: ['my error'] })
      expect(e.isValid()).to.be.false
      e = new ErrorModel({ id: 'myField', errors: ['my error', 'error 2'] })
      expect(e.isValid()).to.be.false
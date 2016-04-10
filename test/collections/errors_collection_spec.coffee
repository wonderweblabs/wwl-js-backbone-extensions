expect  = require('chai').expect
jsdom   = require('mocha-jsdom')
Q       = require('q')

describe 'models/error', ->

  Collection = require('../../lib/collections/errors_collection')


  # ------------------------------------------------------------------
  describe '#isValid', ->

    it 'should validate model for passed id', ->
      c = new Collection([{ id: 'field1', errors: [] }, { id: 'field2', errors: ['one'] }])
      expect(c.isValid('field1')).to.be.true
      expect(c.isValid('field2')).to.be.false

    it 'should return true for missing model', ->
      c = new Collection([])
      expect(c.isValid('field1')).to.be.true
      expect(c.isValid('field2')).to.be.true

  # ------------------------------------------------------------------
  describe '#areAllValid', ->

    it 'should be true if models are valid', ->
      c = new Collection([{ id: 'field1', errors: [] }, { id: 'field2' }])
      expect(c.areAllValid()).to.be.true

    it 'should be false if at least one model is not valid', ->
      c = new Collection([{ id: 'field1', errors: [] }, { id: 'field2', errors: ['one'] }])
      expect(c.areAllValid()).to.be.false

    it 'should be true if there are no models', ->
      c = new Collection([])
      expect(c.areAllValid()).to.be.true

  # ------------------------------------------------------------------
  describe '#getMessages', ->

    it 'should return empty array if there are no models', ->
      c = new Collection([])
      expect(c.getMessages()).to.be.eql([])

    it 'should map messages of the models', ->
      c = new Collection([{ id: '1', errors: 'Test1' }, { id: '2', errors: ['Test2'] }])
      expect(c.getMessages()).to.be.eql(['Test1', 'Test2'])

    it 'should flatten messages', ->
      c = new Collection([{ id: '1', errors: 'Test1' }, { id: '2', errors: ['Test2', 'Test3'] }])
      expect(c.getMessages()).to.be.eql(['Test1', 'Test2', 'Test3'])


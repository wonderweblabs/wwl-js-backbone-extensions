chai    = require('chai')
chai.use(require('chai-things'))

expect  = chai.expect
jsdom   = require('mocha-jsdom')
Q       = require('q')

describe 'models/abstract', ->

  context: null

  AbstractModel = require('../../lib/models/abstract')
  Model         = require('../fixtures/simple_model')

  beforeEach (cb) ->
    context = new (require('wwl-js-app-context'))({ root: true })
    Q(context.configure()).then(-> cb()).done()


  # ------------------------------------------------------------------
  describe '#getLocalErrors and #getRemoteErrors', ->

    it 'should return any empty local errors collection', ->
      m = new Model({}, { context: context })
      expect(m.getLocalErrors().any()).to.be.false

    it 'should return any empty remote errors collection', ->
      m = new Model({}, { context: context })
      expect(m.getRemoteErrors().any()).to.be.false

  # ------------------------------------------------------------------
  describe '#isLocalValid and #isRemoteValid', ->

    it 'should return true for no errors', ->
      m = new Model({}, { context: context })
      expect(m.isLocalValid()).to.be.true
      expect(m.isRemoteValid()).to.be.true

    it 'should check remote validity for one attribute', ->
      m = new Model({}, { context: context })
      m.getRemoteErrors().add({ id: 'test1', errors: 'wrong' })
      m.getRemoteErrors().add({ id: 'test2' })

      expect(m.isRemoteValid('test1')).to.be.false
      expect(m.isRemoteValid('test2')).to.be.true
      expect(m.isRemoteValid('test3')).to.be.true

  # ------------------------------------------------------------------
  describe '#parse', ->

    it 'should extract remote errors from attributes', ->
      m = new Model({}, { context: context })
      m.parse({
        data:
          errors:
            'val1': 'Test'
            'val2': ['t2', 't3']
      })

      array = m.getRemoteErrors().toJSON()

      expect(array).to.include.something.that.deep.equals(
        { id: 'val1', errors: ['Test'] }
      )
      expect(array).to.include.something.that.deep.equals(
        { id: 'val2', errors: ['t2', 't3'] }
      )

    it 'should extract remote errors from meta data', ->
      m = new Model({}, { context: context })
      m.parse({
        data: { errors: { 'val1': 'Test' } }
        meta: { errors: { 'val2': ['t2', 't3'] } }
      })

      array = m.getRemoteErrors().toJSON()

      expect(array).to.include.something.that.deep.equals(
        { id: 'val1', errors: ['Test'] }
      )
      expect(array).to.include.something.that.deep.equals(
        { id: 'val2', errors: ['t2', 't3'] }
      )

    it 'should reset remote errors collection', ->
      m = new Model({}, { context: context })
      m.getRemoteErrors().add({ id: 'test1', errors: 'wrong' })

      expect(m.getRemoteErrors().any()).to.be.true
      m.parse({ data: {} })
      expect(m.getRemoteErrors().any()).to.be.false





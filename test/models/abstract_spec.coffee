expect  = require('chai').expect
jsdom   = require('mocha-jsdom')
Q       = require('q')

chai.use(require('chai-things'))

describe 'models/abstract', ->

  context: null

  AbstractModel = require('../../lib/models/abstract')
  Model         = require('../fixtures/simple_model')

  beforeEach (cb) ->
    context = new (require('wwl-js-app-context'))({ root: true })
    Q(context.configure()).then(-> cb()).done()


  # ------------------------------------------------------------------
  describe '#constructor', ->

    it 'should raise error for missing context', ->
      expect(-> new Model()).to.throw()

    it 'should instantiate with context and default rootName', ->
      expect(-> new Model({}, { context: context })).to.not.throw()

    it 'should define "data" as default rootName', ->
      m = new Model({}, { context: context })
      expect(m.rootName).to.eql('data')

  # ------------------------------------------------------------------
  describe '#getOption', ->

    it 'should resolve value from prototype', ->
      Model.prototype.test = 100
      m = new Model({}, { context: context })
      expect(m.getOption('test')).to.eql(100)

    it 'should resolve value from passed options', ->
      m = new Model({}, { context: context, test: '500' })
      expect(m.getOption('test')).to.eql('500')

    it 'should prefer passed options for same value ', ->
      Model.prototype.test = 100
      m = new Model({}, { context: context, test: '500' })
      expect(m.getOption('test')).to.eql('500')

    it 'should resolve value of a function too', ->
      Model.prototype.test = -> 'Hello World'
      m = new Model({}, { context: context, test2: -> 1000 })
      expect(m.getOption('test')).to.eql('Hello World')
      expect(m.getOption('test2')).to.eql(1000)

  # ------------------------------------------------------------------
  describe '#getMeta', ->

    it 'should return empty obj by default', ->
      m = new Model({}, { context: context })
      expect(m.getMeta()).to.eql({})

  # ------------------------------------------------------------------
  describe '#getRandomBinaryId', ->

    it 'should throw for abstract implementation', ->
      m = new AbstractModel({}, { context: context })
      expect(-> m.getRandomBinaryId()).to.throw()

    it 'should return random string for simple test implementation', ->
      m = new Model({}, { context: context })
      str = m.getRandomBinaryId()
      expect(str).to.be.a('string')
      expect(str).to.not.eql(m.getRandomBinaryId())

  # ------------------------------------------------------------------
  describe '#prependedUrlRoot', ->

    it 'should return the urlRoot attribute by default', ->
      Model.prototype.urlRoot = '/test'
      m = new Model({}, { context: context })
      expect(m.prependedUrlRoot()).to.eql('/test')

  # ------------------------------------------------------------------
  describe '#unsetAll', ->

    it 'should unset all attributes except of the id', ->
      m = new Model({ id: 1, val1: '1', val2: 2 }, { context: context })
      expect(m.attributes).to.eql({ id: 1, val1: '1', val2: 2 })
      m.unsetAll()
      expect(m.attributes).to.eql({ id: 1 })

    it 'should unset all attributes including id for discardId:true', ->
      m = new Model({ id: 1, val1: '1', val2: 2 }, { context: context })
      expect(m.attributes).to.eql({ id: 1, val1: '1', val2: 2 })
      m.unsetAll({ discardId: true })
      expect(m.attributes).to.eql({ })

  # ------------------------------------------------------------------
  describe '#toSyncJSON', ->

    it 'should scope json under rootName', ->
      m = new Model({ test: 1, test2: 'jo' }, { context: context })
      expect(m.toSyncJSON()).to.eql({ data: { test: 1, test2: 'jo' } })

    it 'should not scope json under rootName if option syncWithoutRoot is true', ->
      m = new Model({ test: 1, test2: 'jo' }, { context: context, syncWithoutRoot: true })
      expect(m.toSyncJSON()).to.eql({ test: 1, test2: 'jo' })

    it 'should not scope json under rootName if passed option withoutRoot is true', ->
      m = new Model({ test: 1, test2: 'jo' }, { context: context })
      expect(m.toSyncJSON({ withoutRoot: true })).to.eql({ test: 1, test2: 'jo' })

    it 'should remove attributes listed in jsonOmitted', ->
      m = new Model({ t1: 1, t2: 2, t3: 3, t4: 4 }, { context: context, jsonOmitted: ['t3'] })
      expect(m.toSyncJSON()).to.eql({ data: { t1: 1, t2: 2, t4: 4 } })

    it 'should only include attributes listed in jsonPermitted', ->
      m = new Model({ t1: 1, t2: 2, t3: 3, t4: 4 }, { context: context, jsonPermitted: ['t2', 't3'] })
      expect(m.toSyncJSON()).to.eql({ data: { t2: 2, t3: 3 } })

    it 'should remove attributes listed in jsonPermitted and in jsonOmitted', ->
      m = new Model({ t1: 1, t2: 2, t3: 3, t4: 4 }, {
        context: context
        jsonOmitted: ['t3']
        jsonPermitted: ['t2', 't3']
      })

      expect(m.toSyncJSON()).to.eql({ data: { t2: 2 } })

  # ------------------------------------------------------------------
  describe 'binaryId feature', ->

    it 'should be binaryId:false by default', ->
      m = new Model({}, { context: context })
      expect(m.getOption('binaryId')).to.be.false

    it 'should not set id if binaryId:false', ->
      m = new Model({}, { context: context })
      expect(m.id).to.be.undefined
      expect(m.get('id')).to.be.undefined

    it 'should set binary id on create if binaryId:true', ->
      m = new Model({}, { context: context, binaryId: true })
      expect(m.id).to.be.a('string')
      expect(m.get('id')).to.be.a('string')
      expect(m.id).to.eql(m.get('id'))
      expect(m.id.length).to.be.above(0)

  # ------------------------------------------------------------------
  describe '#isNew', ->

    it 'should be true for new instance', ->
      m = new Model({}, { context: context })
      expect(m.isNew()).to.be.true

    it 'should be true for new binaryId instance', ->
      m = new Model({}, { context: context, binaryId: true })
      expect(m.isNew()).to.be.true

  # ------------------------------------------------------------------
  describe 'dirty', ->

    it 'should not be dirty by default', ->
      m = new Model({}, { context: context })
      expect(m.isDirty()).to.be.false

    it 'should be dirty after changing an attribute', ->
      m = new Model({}, { context: context })
      m.set('name', 'Tester')
      expect(m.isDirty()).to.be.true

    it 'should not be dirty after syncing', (cb) ->
      server = sinon.fakeServer.create()
      server.autoRespond = true
      server.respondWith(
        JSON.stringify({
          data:
            id:         1
            name:       'Tester'
            updated_at: Date.now()
        })
      )

      m = new Model({ id: 1 }, { context: context } )
      m.set('name', 'Tester')
      expect(m.isDirty()).to.be.true

      m.save().then ->
        expect(m.isDirty()).to.be.false
        server.restore()
        cb()

    it 'should be dirty after syncing with same updated_at', (cb) ->
      date    = Date.now()
      server  = sinon.fakeServer.create()
      server.autoRespond = true
      server.respondWith(
        JSON.stringify({
          data:
            id:         1
            name:       'Tester'
            updated_at: date
        })
      )

      m = new Model({ id: 1, updated_at: date }, { context: context } )
      m.set('name', 'Tester')
      expect(m.isDirty()).to.be.true

      m.save().then ->
        expect(m.isDirty()).to.be.true
        server.restore()
        cb()

    it 'should be trigger event on dirty change', ->
      m = new Model({}, { context: context })
      e = 0

      m.on 'dirty:change', (m, d) -> e += 1

      m.setDirty()
      m.setDirty(false)
      m.off()

      expect(e).to.eql(2)




expect  = require('chai').expect
jsdom   = require('mocha-jsdom')
Q       = require('q')

describe 'collections/abstract_collection', ->

  context = null

  Collection = require('../fixtures/simple_collection')

  beforeEach (cb) ->
    context = new (require('wwl-js-app-context'))({ root: true })
    Q(context.configure()).then(-> cb()).done()


  # ------------------------------------------------------------------
  describe '#constructor', ->

    it 'should raise error for missing context', ->
      expect(-> new Collection()).to.throw()

    it 'should instantiate with context and default rootName', ->
      expect(-> new Collection([], { context: context })).to.not.throw()

    it 'should define "data" as default rootName', ->
      c = new Collection([], { context: context })
      expect(c.rootName).to.eql('data')

  # ------------------------------------------------------------------
  describe '#getOption', ->

    it 'should resolve value from prototype', ->
      Collection.prototype.test = 100
      c = new Collection([], { context: context })
      expect(c.getOption('test')).to.eql(100)

    it 'should resolve value from passed options', ->
      c = new Collection([], { context: context, test: '500' })
      expect(c.getOption('test')).to.eql('500')

    it 'should prefer passed options for same value ', ->
      Collection.prototype.test = 100
      c = new Collection([], { context: context, test: '500' })
      expect(c.getOption('test')).to.eql('500')

    it 'should resolve value of a function too', ->
      Collection.prototype.test = -> 'Hello World'
      c = new Collection([], { context: context, test2: -> 1000 })

      expect(c.getOption('test')).to.eql('Hello World')
      expect(c.getOption('test2')).to.eql(1000)

  # ------------------------------------------------------------------
  describe '#getMeta', ->

    it 'should return empty obj by default', ->
      c = new Collection([], { context: context })
      expect(c.getMeta()).to.eql({})

  # ------------------------------------------------------------------
  describe '#prependedUrlRoot', ->

    it 'should return the url attribute by default', ->
      Collection.prototype.url = '/test'
      c = new Collection([], { context: context })
      expect(c.prependedUrlRoot()).to.eql('/test')

  # ------------------------------------------------------------------
  describe '#toSyncJSON', ->

    it 'should scope json under rootName', ->
      c = new Collection([{ test: 1 }, { test: 2 }], { context: context })

      expect(c.toSyncJSON()).to.eql({
        data: [
          { test: 1 },
          { test: 2 }
        ]
      })

    it 'should not scope json under rootName if option syncWithoutRoot is true', ->
      c = new Collection([{ test: 1 }, { test: 2 }], { context: context, syncWithoutRoot: true })

      expect(c.toSyncJSON()).to.eql([
        { test: 1 },
        { test: 2 }
      ])

    it 'should not scope json under rootName if passed option withoutRoot is true', ->
      c = new Collection([{ test: 1 }, { test: 2 }], { context: context })

      expect(c.toSyncJSON({ withoutRoot: true })).to.eql([
        { test: 1 },
        { test: 2 }
      ])

  # ------------------------------------------------------------------
  describe '#_prepareModel', ->

    it 'should set context on it\'s models', ->
      c = new Collection([{ test: 1 }], { context: context })
      expect(c.first().context).to.eql(context)



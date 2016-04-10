chai    = require('chai')
chai.use(require('chai-things'))

expect  = chai.expect
jsdom   = require('mocha-jsdom')
Q       = require('q')

$       = require('backbone').$

describe 'models/abstract', ->

  context       = null
  server        = null

  AbstractModel = require('../../lib/models/abstract')
  Model         = require('../fixtures/simple_model')

  beforeEach (cb) ->
    context = new (require('wwl-js-app-context'))({ root: true })
    Q(context.configure()).then(-> cb()).done()


  # ------------------------------------------------------------------
  describe 'general', ->

    beforeEach ->
      sinon.spy($, 'ajax')

    afterEach ->
      $.ajax.restore()

    it 'make ajax request', (cb) ->
      m = new Model({}, { context: context })
      m.save()

      expect($.ajax.calledOnce).to.be.true

      cb()

  # ------------------------------------------------------------------
  describe '#sync concerning prependedUrl', ->

    oldAjax             = null
    oldPrependedUrlRoot = null

    beforeEach ->
      sinon.spy($, 'ajax')
      oldAjax = $.ajax

      oldPrependedUrlRoot = Model.prototype.prependedUrlRoot
      Model.prototype.prependedUrlRoot = -> 'http://my.own.path/url'

    afterEach ->
      Model.prototype.prependedUrlRoot = oldPrependedUrlRoot
      $.ajax.restore()

    it 'should modify url based on prependedUrl', (cb) ->
      $.ajax = (settings) =>
        $.ajax = oldAjax
        expect(settings.url).to.eql('http://my.own.path/url')
        cb()

      m = new Model({}, { context: context })
      m.save()

    it 'should not modify url based on prependedUrl if url is passed as option', (cb) ->
      $.ajax = (settings) =>
        $.ajax = oldAjax
        expect(settings.url).to.eql('http://some.other.url')
        cb()

      m = new Model({}, { context: context })
      m.save({}, { url: 'http://some.other.url' })

  # ------------------------------------------------------------------
  describe '#sync concerning attributes/toSyncJSON', ->

    oldAjax = null

    beforeEach ->
      sinon.spy($, 'ajax')
      oldAjax = $.ajax

    afterEach ->
      $.ajax.restore()

    it 'should set attributes based on toSyncJSON', (cb) ->
      $.ajax = (settings) =>
        $.ajax = oldAjax
        expect(settings.data).to.eql(JSON.stringify({ data: { id: 1, title: 'test' } }))
        cb()

      m = new Model(
        { id: 1, title: 'test', t3: 't3' },
        { context: context, jsonPermitted: ['id', 'title'] }
      )
      m.save()

    it 'should not set attributes if attrs are passed', (cb) ->
      $.ajax = (settings) =>
        $.ajax = oldAjax
        expect(settings.data).to.eql(JSON.stringify({ t5: 't5' }))
        cb()

      m = new Model(
        { id: 1, title: 'test', t3: 't3' },
        { context: context, jsonPermitted: ['id', 'title'] }
      )
      m.save({}, { attrs: { t5: 't5' } })

  # ------------------------------------------------------------------
  describe '#sync concerning isSyncing', ->

    it 'should set syncing to true', (cb) ->
      oldAjax = $.ajax

      $.ajax = (settings) =>
        $.ajax = oldAjax
        expect(m.isSyncing()).to.be.true
        cb()

      m = new Model({ id: 1 }, { context: context } )
      expect(m.isSyncing()).to.be.false
      m.save()

    it 'should set syncing to true after sync process', (cb) ->
      server = sinon.fakeServer.create()
      server.autoRespond = true
      server.respondWith(JSON.stringify({ data: { "id": 1 } }))

      m = new Model({ id: 1 }, { context: context } )
      expect(m.isSyncing()).to.be.false

      m.save({ title: 'new' }).then ->
        expect(m.isSyncing()).to.be.false
        server.restore()
        cb()

  # ------------------------------------------------------------------
  describe '#sync concerning isSynced', ->

    it 'should be synced after save', (cb) ->
      server = sinon.fakeServer.create()
      server.autoRespond = true
      server.respondWith(JSON.stringify({ data: { id: 1 } }))

      m = new Model({ id: 1 }, { context: context } )
      expect(m.isSynced()).to.be.false

      m.save({ title: 'new' }).then ->
        expect(m.isSynced()).to.be.true

        server.restore()
        cb()

  # ------------------------------------------------------------------
  describe '#sync concerning remote errors', ->

    it 'should set remote errors', (cb) ->
      server = sinon.fakeServer.create()
      server.autoRespond = true
      server.respondWith(
        JSON.stringify({
          data:
            id: 1
            errors: { 'test': 'Some' }
          meta:
            errors: { 'test2': 'Some other' }
        })
      )

      m = new Model({ id: 1 }, { context: context } )

      m.save({ title: 'new' }).then ->
        expect(m.isRemoteValid()).to.be.false
        expect(m.getRemoteErrors().size()).to.eql(2)

        server.restore()
        cb()













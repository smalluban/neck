describe 'Router', ->

  it 'should throw when initialize without Neck.App', ->
    assert.throw ->
      new Neck.Router()

  describe "route method", ->

    callback = null
    _route = null
    r = null
    app = null

    beforeEach ->
      _route = Backbone.Router.prototype.route
      Backbone.Router.prototype.route = callback = sinon.spy()
      app = new Neck.Controller()
      r = new Neck.Router app: app

    afterEach ->
      Backbone.Router.prototype.route = _route

    it 'should throw with wrong settings', ->
      assert.throw -> r.route 'some', 1
      assert.throw -> r.route 'some', undefined
      assert.throw -> r.route 'some', null

    it 'should prepare settings', ->
      assert.deepEqual r._createSettings('controllerName'), {
        yields: 
          main: 
            controller: 'controllerName'
      }

      assert.deepEqual r._createSettings(controller: 'name', refresh: true, replace: false), {
        yields: 
          main: 
            controller: 'name'
            refresh: true
            replace: false
      }

    
      assert.deepEqual r._createSettings(yields: main: controller: 'name'), {
        yields: 
          main: 
            controller: 'name'
      }

    it "should throw when there is no proper yield", ->
      r.route 'some', 'mainController'
      action = callback.args[0][1]

      assert.throw ->
        action('some')
      , "No 'main' yield defined in App"

    it "should append yield", ->
      append = sinon.spy()
      app._yieldList =
        main:
          append: append

      r.route 'some/:id', 'mainController'
      action = callback.args[0][1]

      action(1)
      assert.equal append.args[0][0], 'mainController'
      assert.deepEqual append.args[0][1], id: 1

      # For "https://github.com/jhudson8/backbone-query-parameters"
      action(1, {some: 'other'})
      assert.equal append.args[1][0], 'mainController'
      assert.deepEqual append.args[1][1], id: 1, some: 'other'

    it "should clear yield when is set to false", ->
      clear = sinon.spy()
      app._yieldList =
        main:
          clear: clear

      r.route 'some', yields: main: false
      action = callback.args[0][1]

      action()

      assert.ok clear.called

    it "should set app scope '_state' property when it is set in settings", ->
      app._yieldList =
        main:
          append: ->

      r.route 'some', 
        yields: 
          main: controller: 'someController'
        state: 'myState'

      action = callback.args[0][1]
      action()

      assert.equal app.scope._state, 'myState'

describe 'App', ->

  it "should create router when routes object is set", ->
    class App extends Neck.App
      routes:
        'some': 'someController'

    app = new App()
    assert.instanceOf app.router, Neck.Router
    assert.equal app.router.app, app

  it "should call history start when history property is set", (done)->
    class App extends Neck.App
      template: false
      routes:
        'some': 'someController'

    callback = sinon.spy(Backbone.history, 'start')
    app = (new App()).render()

    setTimeout ->
      console.dir Backbone.history.start
      assert.ok callback.calledWith app.history

      Backbone.history.start.restore()
      done()
      

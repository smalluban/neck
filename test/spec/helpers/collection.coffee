describe "[ui-collection]", ->

  c = null

  beforeEach ->
    c = new Neck.Controller()

  it "should use inner nodes as template", ->
    c.scope.collection = new Backbone.Collection []
    h = new Neck.Helper.collection parent: c, el: $('<div><span></span></div>'), mainAttr: "collection"

    assert.equal h.el.innerHTML, ''
    c.scope.collection.add name: 'asd'
    assert.equal h.el.innerHTML, '<span></span>'
    c.scope.collection.add name: 'asd'
    assert.equal h.el.innerHTML, '<span></span><span></span>'

  it "should use empty template", ->
    c.scope.collection = new Backbone.Collection []
    c.scope.empty = "<p>empty</p>"
    h = new Neck.Helper.collection parent: c, el: $('<div collection-empty="empty"><span></span></div>'), mainAttr: "collection"

    assert.equal h.el.innerHTML, "<p>empty</p>"

  it "should use external view", ->
    c.scope.collection = new Backbone.Collection [{name: 'asd'}]
    c.scope.view = (scope)-> "<p>#{scope.item.get('name')}</p>"
    h = new Neck.Helper.collection parent: c, el: $('<div collection-view="view"></div>'), mainAttr: "collection"

    assert.equal h.el.innerHTML, "<p>asd</p>"

  it "should use external item controller as string", ->
    c.scope.collection = new Backbone.Collection []
    c.injector = load: sinon.spy()
  
    h = new Neck.Helper.collection parent: c, el: $("<div collection-controller='\"someController\"'></div>"), mainAttr: "collection"

    assert.ok c.injector.load.calledWith 'someController'
    assert.deepEqual c.injector.load.args[0][1], type: 'controller'

  it "should use external item controller as property", ->
    c.scope.collection = new Backbone.Collection []
    c.scope.controller = {}

    h = new Neck.Helper.collection parent: c, el: $("<div collection-controller=\"controller\"></div>"), mainAttr: "collection"
    assert.equal h.itemController, c.scope.controller
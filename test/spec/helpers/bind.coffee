describe '[ui-bind]', ->

  c = null

  beforeEach ->
    c = new Neck.Controller()
    c.scope.text = 'someValue'
    c.scope.htmlText = '<b>someValue</b>'
    c.scope.boolTrue = true
    c.scope.boolFalse = false

  it 'should set proper value and listen changes', ->
    h = new Neck.Helper.bind parent: c, el: $('<div/>'), mainAttr: "text"
    assert.equal h.el.outerHTML, "<div>someValue</div>"
    c.scope.text = 'newValue'
    assert.equal h.el.outerHTML, "<div>newValue</div>"

    h = new Neck.Helper.bind parent: c, el: $('<div/>'), mainAttr: "htmlText"
    assert.equal h.el.outerHTML, "<div><b>someValue</b></div>"

    h = new Neck.Helper.bind parent: c, el: $('<input type="text"/>'), mainAttr: "text"
    assert.equal h.$el.val(), "newValue"
    c.scope.text = 'someValue'
    assert.equal h.$el.val(), "someValue"

    h = new Neck.Helper.bind parent: c, el: $('<input type="checkbox"/>'), mainAttr: "boolTrue"
    assert.equal h.$el.prop('checked'), true
    c.scope.boolTrue = false
    assert.equal h.$el.prop('checked'), false

  it 'should set number value', (done)->
    h = new Neck.Helper.bind parent: c, el: $('<input type="text"/>'), mainAttr: "number"
    h.$el.val 12.12
    h.$el.trigger "change"

    setTimeout ->
      assert.equal c.scope.number, 12.12
      assert.isNumber c.scope.number 
      done()

  it 'should set number value as string', (done)->
    h = new Neck.Helper.bind parent: c, el: $('<input type="text" bind-number="false" />'), mainAttr: "number"
    h.$el.val 12.12
    h.$el.trigger "change"

    setTimeout ->
      assert.equal c.scope.number, "12.12"
      assert.isString c.scope.number
      done()

  it 'should listen to updates from input change', (done)->
    h = new Neck.Helper.bind parent: c, el: $('<input type="text"/>'), mainAttr: "text"
    assert.equal h.$el.val(), "someValue"
    h.$el.val "newValue"
    h.$el.trigger "change"
    
    setTimeout ->
      assert.equal c.scope.text, "newValue"
      done()

  it 'should listen to updates from checkbox change', (done)->
    h = new Neck.Helper.bind parent: c, el: $('<input type="checkbox"/>'), mainAttr: "boolTrue"
    assert.equal h.$el.prop('checked'), true
    h.$el.prop "checked", false
    h.$el.trigger "change"
    
    setTimeout ->
      assert.equal c.scope.boolTrue, false
      done()

  it 'should listen to updates from node change', (done)->
    h = new Neck.Helper.bind parent: c, el: $('<div/>'), mainAttr: "text"
    h.el.innerHTML = "<b>newValue</b>"
    h.$el.trigger "change"
    
    setTimeout ->
      assert.equal c.scope.text, "<b>newValue</b>"
      done()

  it 'should not throw error when update trigger remove helper', ->
    h = new Neck.Helper.bind parent: c, el: $('<div/>'), mainAttr: "text" 
    assert.doesNotThrow ->
      h.$el.trigger "change"
      h.remove()

  it "should throw error for model without 'bind-property' set", ->
    assert.throw ->
      c.scope.model = new Backbone.Model()
      h = new Neck.Helper.bind parent: c, el: $('<div/>'), mainAttr: "model"

  it "should throw error for 'bind-property' not set as string", ->
    assert.throw ->
      c.scope.model = new Backbone.Model()
      h = new Neck.Helper.bind parent: c, el: $('<div bind-property="123"></div>'), mainAttr: "model"

  it "should bind Backbone.Model attribute", (done)->
    c.scope.model = new Backbone.Model(name: "some name")
    h = new Neck.Helper.bind parent: c, el: $("<div bind-property=\"'name'\"></div>"), mainAttr: "model"

    assert.equal h.$el.html(), "some name"
    c.scope.model.set "name", "new name"
    assert.equal h.$el.html(), "new name"

    h.el.innerHTML = "some name"
    h.$el.trigger "change"

    setTimeout ->
      assert.equal c.scope.model.get("name"), "some name"
      done()

  it "should listen to new model", ->
    c.scope.model = new Backbone.Model(name: "some name")
    h = new Neck.Helper.bind parent: c, el: $("<div bind-property=\"'name'\"></div>"), mainAttr: "model"
    c.scope.model = new Backbone.Model(name: "new name")

    assert.equal h.el.innerHTML, "new name"

  it "should listen to new property other than model", ->
    c.scope.model = new Backbone.Model(name: "some name")
    h = new Neck.Helper.bind parent: c, el: $("<div bind-property=\"'name'\"></div>"), mainAttr: "model"
    c.scope.model = "asd"

    assert.equal h.el.innerHTML, "asd"
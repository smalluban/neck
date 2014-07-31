describe '[ui-class]', ->

  c = null

  beforeEach ->
    c = new Neck.Controller()
    c.scope.text = 'someValue'
    c.scope.boolTrue = true
    c.scope.boolFalse = false

  it 'should throw when main accessor is not object', ->
    assert.throw ->
      h = new Neck.Helper.class parent: c, el: $('<div>'), mainAttr: "'asd'"
    , "'ui-class' attribute has to be object"

  it 'should set attributes to node', ->
    h = new Neck.Helper.class parent: c, el: $('<div>'), mainAttr: "{some: text, other: boolTrue, else: boolFalse}"
    assert.ok h.$el.hasClass('some')
    assert.ok h.$el.hasClass('other')
    assert.notOk h.$el.hasClass('else')

    c.scope.boolTrue = false
    assert.notOk h.$el.hasClass('other')

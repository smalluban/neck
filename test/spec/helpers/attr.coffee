describe '[ui-attr]', ->

  c = null

  beforeEach ->
    c = new Neck.Controller()
    c.scope.text = 'someValue'
    c.scope.boolTrue = true
    c.scope.boolFalse = false

  it 'should throw when main accessor is not object', ->
    assert.throw ->
      h = new Neck.Helper.attr parent: c, el: $('<div>'), mainAttr: "'asd'"
    , "'ui-attr' attribute has to be object"

  it 'should set attributes to node', ->
    h = new Neck.Helper.attr parent: c, el: $('<div>'), mainAttr: "{some: text, other: boolTrue, else: boolFalse}"
    assert.equal h.$el.attr('some'), 'someValue'
    assert.equal h.$el.attr('other'), 'other'
    assert.isUndefined h.$el.attr('else')

    c.scope.text = 'newValue'
    assert.equal h.$el.attr('some'), 'newValue'

    c.scope.boolTrue = false
    assert.isUndefined h.$el.attr('other')

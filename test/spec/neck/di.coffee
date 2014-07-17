describe "'globals' dependency injector", ->

  it 'should return global variable', ->
    window.something = "testCase"
    assert.equal Neck.DI.globals.load("something", type: 'controller'), "testCase"
    window.something = undefined

  it 'should throw error if variable not exist', ->
    assert.throw -> Neck.DI.globals.load("something", type: 'controller')

  it 'should return ID when template variable not exist', ->
    assert.equal Neck.DI.globals.load("<p>asd</p>", type: 'template'), "<p>asd</p>"
    assert.equal Neck.DI.globals.load("something", type: 'template'), "something"

describe "'commonjs' dependency injector", ->

  beforeEach ->
    window.require = sinon.spy()

  afterEach ->
    window.require = undefined

  it "should return template body when ID is not path for template", ->
    assert.equal Neck.DI.commonjs.load("<p>asd</p>", type: 'template'), "<p>asd</p>"

  it "should call require when ID is path for template", ->
    Neck.DI.commonjs.load("asd", type: 'template')
    assert.ok window.require.calledWith "templates/asd"

  it "should call require for controller", ->
    Neck.DI.commonjs.load("asd", type: 'controller')
    assert.ok window.require.calledWith "controllers/asd"

  it "should call require for helper", ->
    Neck.DI.commonjs.load("asd", type: 'helper')
    assert.ok window.require.calledWith "helpers/asd"

  it "should throw error when no ID is found", ->
    window.require = -> throw "Error"
    assert.throw -> 
      Neck.DI.commonjs.load("asd", type: 'controller')
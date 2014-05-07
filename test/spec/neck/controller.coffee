describe 'Controller', ->
  container = null

  beforeEach -> container = $('<div/>')
  afterEach -> container.remove()

  # 'template' property tests
  
  it "should render nothing when template is set to 'false'", ->
    class Controller extends Neck.Controller
      template: false

    controller = new Controller el: container
    controller.render()
    assert.equal container.html(), ''

  it "should set template to body of node when template is set to 'true'", ->
    exampleTemplate = "<p>Example text</p>"
    class Controller extends Neck.Controller
      template: true

    container.html exampleTemplate
    controller = new Controller el: container
    
    # After initialize template property is now string with node body text
    assert.equal controller.template, exampleTemplate

    controller.render()
    assert.equal container.html(), exampleTemplate

  it "should try to load template by DI when template is string", ->
    class Controller extends Neck.Controller
      template: "pathToTemplate"

    controller = new Controller el: container

    # Fake DI injector for testing purpose
    loader = sinon.spy()
    controller.injector = load: loader

    controller.render()
    assert.ok loader.calledOnce
    assert.ok loader.calledWith "pathToTemplate"
    # DI module should get options object with type property set to 'template'
    assert.equal loader.args[0][1].type, "template"

  it "should call function and put returned result when template is function", ->
    class Controller extends Neck.Controller
      template: (scope)-> "<p>#{scope.text}</p>"
      constructor: ->
        super
        @scope.text = "Sample text"

    controller = new Controller el: container
    controller.render()

    assert.equal container.html(), "<p>Sample text</p>"

  # 'divWrapper' property tests

  it "should wrap template body with 'div' when divWrapper is true", ->
    class Controller extends Neck.Controller
      divWrapper: true # defaults is true, so it is not neccesary here
      template: '<p>This is text</p>'

    controller = new Controller()
    controller.render()
    assert.equal controller.el.outerHTML, "<div><p>This is text</p></div>"

  it "should set root element to body of template when divWrapper is false", ->
    class Controller extends Neck.Controller
      divWrapper: false
      template: '<p>This is text</p>'

    controller = new Controller()
    controller.render()
    assert.equal controller.el.outerHTML, "<p>This is text</p>"

  it "should not change element root when it is already set", ->
    class Controller extends Neck.Controller
      template: "<li>This is text</li>"

    container = $("<ul/>")
    controller = new Controller el: container
    controller.render()

    assert.equal controller.el.outerHTML, "<ul><li>This is text</li></ul>"

  # 'parseSelf' property tests

  # Set to true will trigger parsing proccess within root node, false set to
  # parse only childrens of controller root node.

  # Parsing self flag is important for helpers mostly. They should not trigger
  # this action, because it's already started by controller, so when helper
  # is initialized parsing proccess from controller will continue work on that node.

  it "should start parsing from root when parseSelf is true", ->
    class Controller extends Neck.Controller
      parseSelf: true
      template: "<p>This is text</p>"

    controller = new Controller el: container
    spy = controller._parseNode = sinon.spy()
    controller.render()

    assert.ok spy.calledOnce
    assert.equal spy.args[0][0].outerHTML, "<div><p>This is text</p></div>"

  it "should parse only children of root node when parseSelf is false", ->
    class Controller extends Neck.Controller
      parseSelf: false
      template: "<p>This is text 1</p><p>This is text 2</p>"

    controller = new Controller el: container
    spy = controller._parseNode = sinon.spy()
    controller.render()

    assert.ok spy.calledTwice
    assert.equal spy.args[0][0].outerHTML, "<p>This is text 1</p>"
    assert.equal spy.args[1][0].outerHTML, "<p>This is text 2</p>"
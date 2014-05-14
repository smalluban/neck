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

  it "should use template from contrcutor options when set", ->
    controller = new Neck.Controller el: container, template: "<p>Some text</p>"
    controller.render()
    assert.equal controller.template, "<p>Some text</p>"
    assert.equal controller.el.outerHTML, "<div><p>Some text</p></div>"

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

  # Scope tests

  it "should create independent scope with _context set to self when no parent is set", ->
    controller = new Neck.Controller()
    assert.equal controller.scope._context, controller

  it "should set scope properties from prototype", ->
    class Controller extends Neck.Controller
      scope:
        one: 1
        two: 'Some text'

    # Simple controller
    controller = new Controller()

    assert.ok controller.scope.hasOwnProperty 'one'
    assert.equal controller.scope.one, 1

    assert.ok controller.scope.hasOwnProperty 'two'
    assert.equal controller.scope.two, 'Some text'

  it "should inherit scope properites from 'parent' controller scope", ->
    class Controller extends Neck.Controller
      scope: 
        one: 1
        two: some: 'text'

    controller = new Controller() 

    # Child controller with 'parent' setted, will inherit properites
    childController = new Neck.Controller parent: controller
    assert.notOk childController.scope.hasOwnProperty 'one'
    assert.notOk childController.scope.hasOwnProperty 'two'
    assert.equal childController.scope.one, 1
    assert.equal childController.scope.two.some, 'text'

    # Changing value of children scope property (not for objects, only String, Number, Boolean)
    # DOESN't change inherit scope value when they are NOT SETTER/GETTER properites
    childController.scope.one = true
    childController.scope.two = newSome: 'text two'
    assert.equal controller.scope.one, 1
    assert.equal controller.scope.two.some, 'text'

    # Now tricky part, watching proccess changes properites to SETTER/GETTER
    # and then inherited properites are changing it's parent

    # Create new instance of Neck.Controller 
    childController = new Neck.Controller parent: controller
    # Trigger watching proccess
    controller.watch 'one', ->

    # Now 'one' property of controller is setter/getter
    # So changind 'one' property of childController will change 'one' property of controller
    # Hint: setter/getter properties are working as objects
    childController.scope.one = true
    assert.equal controller.scope.one, true

  it "should set scope '_resolves' self own property", ->
    controller = new Neck.Controller()
    assert.isObject controller.scope._resolves

    # Child controller (with parent) should have '_resolves' own property
    # It's important because this property can't be inherited from parent
    # All controller scopes has own '_resolves' property
    childController = new Neck.Controller parent: controller
    assert.isObject childController.scope._resolves
    assert.notEqual controller.scope._resolves, childController.scope._resolves

  # Parsing template tests

  it "should iterate through template and initialize helpers", =>
    class Neck.Helper['firstHelper'] extends Neck.Helper
      check: ->

      constructor: ->
        super
        @check(arguments)

    class Neck.Helper['secondHelper'] extends Neck.Helper
      check: ->

      constructor: ->
        super
        @check(arguments)

    spyFirst = sinon.spy Neck.Helper['firstHelper'].prototype, 'check'
    spySecond = sinon.spy Neck.Helper['secondHelper'].prototype, 'check'

    class Controller extends Neck.Controller
      template: 
        '''
          <div ui-first-helper="test">
            <p ui-second-helper="test"></p>
          </div>
        '''

    controller = new Controller().render()
    assert.ok spyFirst.calledOnce
    assert.ok spySecond.calledOnce
    assert.ok spyFirst.calledBefore spySecond

    delete Neck.Helper['firstHelper']
    delete Neck.Helper['secondHelper']

  it "should respect helpers order in node", =>
    class Neck.Helper['firstHelper'] extends Neck.Helper
      check: ->

      constructor: ->
        super
        @check(arguments)

    class Neck.Helper['secondHelper'] extends Neck.Helper
      check: ->

      constructor: ->
        super
        @check(arguments)

    class Neck.Helper['asdHelper'] extends Neck.Helper
      check: ->

      constructor: ->
        super
        @check(arguments)


    spyFirst = sinon.spy Neck.Helper['firstHelper'].prototype, 'check'
    spySecond = sinon.spy Neck.Helper['secondHelper'].prototype, 'check'
    spyAsd = sinon.spy Neck.Helper['asdHelper'].prototype, 'check'

    class Controller extends Neck.Controller
      template: 
        '''
          <div ui-first-helper="test" ui-second-helper="test" ui-asd-helper="test"></div>
        '''

    controller = new Controller().render()
    assert.ok spyFirst.calledOnce
    assert.ok spySecond.calledOnce
    assert.ok spyAsd.calledOnce

    assert.ok spyFirst.calledBefore spySecond
    assert.ok spySecond.calledBefore spyAsd

    Neck.Helper['firstHelper'].prototype.check = ->
    Neck.Helper['secondHelper'].prototype.check = ->
    Neck.Helper['asdHelper'].prototype.check = ->

    spyFirst = sinon.spy Neck.Helper['firstHelper'].prototype, 'check'
    spySecond = sinon.spy Neck.Helper['secondHelper'].prototype, 'check'
    spyAsd = sinon.spy Neck.Helper['asdHelper'].prototype, 'check'

    class Controller extends Neck.Controller
      template: 
        '''
          <div ui-second-helper="test" ui-asd-helper="test" ui-first-helper="test"></div>
        '''

    controller = new Controller().render()
    assert.ok spyFirst.calledOnce
    assert.ok spySecond.calledOnce
    assert.ok spyAsd.calledOnce

    assert.ok spySecond.calledBefore spyAsd
    assert.ok spySecond.calledBefore spyFirst
    assert.ok spyAsd.calledBefore spyFirst

    delete Neck.Helper['firstHelper']
    delete Neck.Helper['secondHelper']
    delete Neck.Helper['asdHelper']

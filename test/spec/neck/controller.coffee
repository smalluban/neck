describe 'Controller', ->
  container = null

  beforeEach -> container = $('<div/>')
  afterEach -> container.remove()

  describe "'template' property", ->

    it "should use template from constructor options when template is undefined", ->
      controller = new Neck.Controller el: container, template: "<p>Some text</p>"
      assert.equal controller.template, "<p>Some text</p>"

      class Controller extends Neck.Controller
        template: false

      controller = new Controller el: container, template: "<p>Some text</p>"
      assert.equal controller.template, false

  
    it "should not touch `el` when template set to 'false'", ->
      container = $('<div><p>Some text</p></div>')
      class Controller extends Neck.Controller
        template: false

      controller = new Controller el: container
      assert.equal container[0].outerHTML, '<div><p>Some text</p></div>'

    it "should set template to body of node and clear node when template is set to 'true'", ->
      exampleTemplate = "<p>Example text</p>"
      class Controller extends Neck.Controller
        template: true

      container.html exampleTemplate
      controller = new Controller el: container

      assert.equal container[0].outerHTML, '<div></div>'
      assert.equal controller.template, exampleTemplate

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

  describe "'divWrapper' property", ->

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

  describe "'parseSelf' property tests", ->

    # Set to true will trigger parsing proccess within root node, false set to
    # parse only childrens of controller root node.

    # Parsing self flag is important for helpers mostly. They should not trigger
    # this action, because it's already started by controller, so when helper
    # is initialized parsing proccess from controller will continue work on that node.

    it "should start parsing from root when parseSelf is true", ->
      container = $('<div ui-helper=""></div>')
      controller = new Neck.Controller el: container
      
      spy = controller._parseNode = sinon.spy()
      controller.render()

      assert.ok spy.called
      assert.equal spy.args[0][0], controller.el

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

  describe "scope object", ->

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

  describe "parsing template", ->

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

    it "should respect helpers order", =>
      class Neck.Helper['firstHelper'] extends Neck.Helper
        orderPriority: 3
        check: ->

        constructor: ->
          super
          @check(arguments)

      class Neck.Helper['secondHelper'] extends Neck.Helper
        orderPriority: 2
        check: ->

        constructor: ->
          super
          @check(arguments)

      class Neck.Helper['asdHelper'] extends Neck.Helper
        orderPriority: 1
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

      assert.ok spyFirst.calledBefore(spySecond), 'firstHelper called before secondHelper'
      assert.ok spySecond.calledBefore(spyAsd), 'secondHelper called before asdHelper'

      Neck.Helper['firstHelper'].prototype.check = ->
      Neck.Helper['secondHelper'].prototype.check = ->
      Neck.Helper['asdHelper'].prototype.check = ->

      Neck.Helper['firstHelper'].prototype.orderPriority = 1
      Neck.Helper['secondHelper'].prototype.orderPriority = 3
      Neck.Helper['asdHelper'].prototype.orderPriority = 2

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

      assert.ok spySecond.calledBefore(spyAsd), 'secondHelper called before asdHelper'
      assert.ok spySecond.calledBefore(spyFirst), 'secondHelper called before firstHelper'
      assert.ok spyAsd.calledBefore(spyFirst), 'asdHelper called before firstHelper'

      delete Neck.Helper['firstHelper']
      delete Neck.Helper['secondHelper']
      delete Neck.Helper['asdHelper']

    it "reverse buffer if browser reads attributes backwards", ->
      _original = Neck.Controller.REVERSE_PARSING
      Neck.Controller.REVERSE_PARSING = true

      class Neck.Helper['firstHelper'] extends Neck.Helper
        check: ->
        constructor: ->
          super
          @check(arguments)

      class Controller extends Neck.Controller
        template: '<div ui-first-helper="test"></div>'

      controller = new Controller().render()
      delete Neck.Helper['firstHelper']

      # TODO: create expect value to check if test is passing

    it "should stops when helper with template occur (as template set to true)", ->
      class Neck.Helper['firstHelper'] extends Neck.Helper
        check: ->
        constructor: ->
          super
          @check(arguments)

      class Neck.Helper['secondHelper'] extends Neck.Helper
        template: true

        check: ->
        constructor: ->
          super
          @check(arguments)

      class Controller extends Neck.Controller
        template: 
          '''
            <div ui-first-helper="test" ui-second-helper="test">
              <p ui-first-helper="test"></p>
            </div>
          '''

      spyFirst = sinon.spy Neck.Helper['firstHelper'].prototype, 'check'
      spySecond = sinon.spy Neck.Helper['secondHelper'].prototype, 'check'

      controller = new Controller().render()

      assert.ok spyFirst.calledOnce, "First helper occur twice but called once"
      assert.ok spySecond.calledOnce

      delete Neck.Helper['firstHelper']
      delete Neck.Helper['secondHelper']

    it "should stops when helper with template occur (as template set to false)", ->
      class Neck.Helper['firstHelper'] extends Neck.Helper
        check: ->
        constructor: ->
          super
          @check(arguments)

      class Neck.Helper['secondHelper'] extends Neck.Helper
        template: false

        check: ->
        constructor: ->
          super
          @check(arguments)

      class Controller extends Neck.Controller
        template: 
          '''
            <div ui-first-helper="test" ui-second-helper="test">
              <p ui-first-helper="test"></p>
            </div>
          '''

      spyFirst = sinon.spy Neck.Helper['firstHelper'].prototype, 'check'
      spySecond = sinon.spy Neck.Helper['secondHelper'].prototype, 'check'

      controller = new Controller().render()

      assert.ok spyFirst.calledOnce, "First helper occur twice but called once"
      assert.ok spySecond.calledOnce

      delete Neck.Helper['firstHelper']
      delete Neck.Helper['secondHelper']

  describe "removing controller", ->
    it "should trigger proper events", ->
      controller = new Neck.Controller()
      spyBefore = sinon.spy()
      spyAfter = sinon.spy()
      controller.on 'remove:before', spyBefore
      controller.on 'remove:after', spyAfter

      controller.remove()

      assert.ok spyBefore.calledOnce
      assert.ok spyAfter.calledOnce

    it "clears reference to parent and scope", ->
      controller = new Neck.Controller()
      controller.parent = {}

      controller.remove()
      assert.isUndefined controller.parent
      assert.isUndefined controller.scope

  describe "render template", ->

    it "should trigger proper events", (done)->
      controller = new Neck.Controller()
      spyBefore = sinon.spy()
      spyAfter = sinon.spy()
      spyParsing = sinon.spy controller, '_parseNode'
      controller.on 'render:before', spyBefore
      controller.on 'render:after', spyAfter

      controller.render()

      setTimeout =>
        assert.ok spyBefore.calledOnce
        assert.ok spyParsing.calledOnce
        assert.ok spyAfter.calledOnce

        assert.ok spyParsing.calledAfter spyBefore
        assert.ok spyAfter.calledAfter spyParsing
        done()

    it "should use template function", ->
      controller = new Neck.Controller()
      controller.template = sinon.spy()

      controller.render()
      assert.ok controller.template.called
      assert.ok controller.template.calledWith controller.scope

    it "shuld use DI when template ID is given", ->
      spy = sinon.spy()
      controller = new Neck.Controller template: 'asd'
      controller.injector = load: -> return spy

      controller.render()
      assert.ok spy.called
      assert.ok spy.calledWith controller.scope

    it "should listen to parent 'render:after'", (done)->
      spyBefore = sinon.spy()
      spyAfter = sinon.spy()
      class Helper extends Neck.Helper
        template: true
        constructor: ->
          super
          @on 'render:after', -> spyAfter()
          @render()

      c1 = new Neck.Controller()
      c1.template = -> '<p ui-some-helper=""></p>'
      c1.injector = load: -> Helper
      c1.on 'render:after', -> spyBefore()
      c1.render()

      setTimeout ->
        assert.ok spyBefore.called
        assert.ok spyAfter.called
        assert.ok spyBefore.calledBefore spyAfter

        done()

  describe "watching scope properties", ->

    it "should watch changes for own scope property", ->
      callback = sinon.spy()
      class Controller extends Neck.Controller
        scope: someProperty: 1

      controller = new Controller()
      controller.watch 'someProperty', callback
      assert.ok callback.calledOnce
      assert.ok callback.args[0][0], 1

      controller.scope.someProperty = 2
      assert.ok callback.calledTwice
      assert.ok callback.args[1][0], 2

    it "should watch changs for parent scope property", ->
      callback = sinon.spy()
      class Controller extends Neck.Controller
        scope: someProperty: 1

      controller = new Controller()
      child = new Neck.Controller parent: controller
      child.watch 'someProperty', callback

      assert.ok callback.calledOnce
      assert.ok callback.args[0][0], 1

      controller.scope.someProperty = 2
      assert.ok callback.calledTwice
      assert.ok callback.args[1][0], 2

    it "should watch own property when property is not set", ->
      callback = sinon.spy()
      controller = new Neck.Controller()
      child = new Neck.Controller parent: controller

      child.watch 'someProperty', callback

      assert.ok callback.calledOnce
      assert.equal callback.args[0][0], undefined

      child.trigger 'refresh:someProperty'

      assert.ok callback.calledTwice
      assert.equal callback.args[1][0], undefined

      child.scope.someProperty = 2

      assert.ok callback.calledThrice
      assert.equal callback.args[2][0], 2

    it "should watch the same property watching twice", ->
      callback1 = sinon.spy()
      callback2 = sinon.spy()

      controller = new Neck.Controller()
      controller.watch 'some', callback1
      controller.watch 'some', callback2

      controller.scope.some = 'text'

      assert.ok callback1.calledTwice
      assert.ok callback2.calledTwice

    it "should listen to Backbone.Model 'change' event", ->
      callback = sinon.spy()
      c = new Neck.Controller()
      c.scope.model = new Backbone.Model()
      c.watch 'model', callback, false
      c.scope.model.trigger 'change'
      assert.ok callback.called
      assert.equal callback.args[0][0], c.scope.model

      oldModel = c.scope.model
      c.scope.model = new Backbone.Model()
      assert.ok callback.calledTwice
      assert.ok callback.args[1][0], c.scope.model

      oldModel.trigger 'change'
      assert.ok callback.calledTwice

      c.scope.model.trigger 'change'
      assert.ok callback.calledThrice

    it "should listen to Backbone.Collection 'add' event", ->
      callback = sinon.spy()
      c = new Neck.Controller()
      c.scope.model = new Backbone.Collection()
      c.watch 'model', callback, false
      c.scope.model.trigger 'add'
      assert.ok callback.called
      assert.equal callback.args[0][0], c.scope.model

      oldModel = c.scope.model
      c.scope.model = new Backbone.Collection()
      assert.ok callback.calledTwice
      assert.ok callback.args[1][0], c.scope.model

      oldModel.trigger 'add'
      assert.ok callback.calledTwice

      c.scope.model.trigger 'add'
      assert.ok callback.calledThrice

    it "should listen to Backbone.Collection 'remove' event", ->
      callback = sinon.spy()
      c = new Neck.Controller()
      c.scope.model = new Backbone.Collection()
      c.watch 'model', callback, false
      c.scope.model.trigger 'remove'
      assert.ok callback.called
      assert.equal callback.args[0][0], c.scope.model

      oldModel = c.scope.model
      c.scope.model = new Backbone.Collection()
      assert.ok callback.calledTwice
      assert.ok callback.args[1][0], c.scope.model

      oldModel.trigger 'remove'
      assert.ok callback.calledTwice

      c.scope.model.trigger 'add'
      assert.ok callback.calledThrice

    it "should listen to Backbone.Collection 'change' event", ->
      callback = sinon.spy()
      c = new Neck.Controller()
      c.scope.model = new Backbone.Collection()
      c.watch 'model', callback, false
      c.scope.model.trigger 'change'
      assert.ok callback.called
      assert.equal callback.args[0][0], c.scope.model

      oldModel = c.scope.model
      c.scope.model = new Backbone.Collection()
      assert.ok callback.calledTwice
      assert.ok callback.args[1][0], c.scope.model

      oldModel.trigger 'add'
      assert.ok callback.calledTwice

      c.scope.model.trigger 'change'
      assert.ok callback.calledThrice

    it "should not trigger callback when initialize watching", ->
      callback = sinon.spy()
      c = new Neck.Controller
      c.watch 'some', callback, false
      assert.notOk callback.called

  describe "scope property getter", ->

    it "should return scope property value", ->
      c = new Neck.Controller()
      c.scope.some = 1
      getter = c._getter c.scope, 'scope.some'
      assert.equal getter(), 1

    it "should throw error for evaluate is not JS code", ->
      c = new Neck.Controller()

      assert.throw -> 
        getter = c._getter c.scope, "\\//"

    it "should return undefined for not set deep property of undefined", ->
      c = new Neck.Controller()
      
      c.scope.some = 1
      getter = c._getter c.scope, 'scope.other.other'
      assert.equal getter(), undefined

    it "should throw error when getting rise error", ->
      c = new Neck.Controller()

      c.scope.some = ->
        throw 'Error'

      assert.throw -> 
        getter = c._getter c.scope, "scope.some()"
        getter()

  describe "scope property setter", ->

    it "should set new value to property", ->
      c = new Neck.Controller()
      c.scope.some = 1
      setter = c._setter c.scope, 'scope.some'
      setter(2)
      assert.equal c.scope.some, 2

    it "should throw error for evaluate is not JS code", ->
      c = new Neck.Controller()

      assert.throw -> 
        setter = c._setter c.scope, "\\//"

    it "should throw error when getting rise error", ->
      c = new Neck.Controller()

      c.scope.some = ->
        throw 'Error'

      assert.throw -> 
        setter = c._setter c.scope, "scope.some()"
        setter()

  describe "apply change to scope property", ->

    it "should trigger change to scope property", ->
      c = new Neck.Controller()
      callback = sinon.spy()

      c.watch 'some', callback, false
      c.apply 'some'

      assert.ok callback.called

    it "should trigger change to parent controller scope property", ->
      c = new Neck.Controller()
      c.scope.some = 'asd'
      callback = sinon.spy()

      c.watch 'some', callback, false

      child = new Neck.Controller parent: c
      child.apply 'some'
      assert.ok callback.called

  describe "route method", ->

    it "should use default 'main' yield", ->
      callback = sinon.spy()
      c = new Neck.Controller
      c._yieldList = {}
      c._yieldList['main'] =
        append: callback

      c.route 'someController'
      assert.ok callback.called
      assert.ok callback.calledWith 'someController'

    it "should use yield from options", ->
      callback = sinon.spy()
      c = new Neck.Controller
      c._yieldList = {}
      c._yieldList['some'] =
        append: callback

      c.route 'someController', yield: 'some'
      assert.ok callback.called
      assert.ok callback.calledWith 'someController'

    it "should throw when there is no default yield", ->
      callback = sinon.spy()
      c = new Neck.Controller

      assert.throw ->
        c.route 'someController'

    it "should throw when there is no set yield", ->
      callback = sinon.spy()
      c = new Neck.Controller
      c._yieldList = {}
      c._yieldList['main'] =
        append: callback

      assert.throw ->
        c.route 'someController', yield: 'some'

  describe "navigate method", ->
    it "should use default options", ->
      callback = sinon.spy()
      _navigate = Neck.Router.prototype.navigate
      Neck.Router.prototype.navigate = callback
      
      c = new Neck.Controller

      c.navigate 'someController'
      assert.ok callback.called
      assert.ok callback.calledWith 'someController'
      assert.deepEqual callback.args[0][1], trigger: true

      Neck.Router.prototype.navigate = _navigate





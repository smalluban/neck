describe 'Helper', ->

  container = null

  beforeEach -> container = $('<div/>')
  afterEach -> container.remove()

  describe "Accessors", ->

    it "should create main accesor", ->
      callback = sinon.spy()

      class Helper extends Neck.Helper
        _setAccessor: callback

      h = new Helper el: container, mainAttr: 'someValue'

      assert.equal callback.args[0][0], '_main'
      assert.equal callback.args[0][1], 'someValue'

    it "should create accessors from attributes array", ->
      callback = sinon.spy()

      class Helper extends Neck.Helper
        attributes: ['one']
        _setAccessor: callback

      container = $('<div one="text"></div>')
      h = new Helper el: container

      assert.equal callback.args[1][0], 'one'
      assert.equal callback.args[1][1], 'text'

    describe "parsing evaluate", ->

      it "should return properties in scope context", ->
        h = new Neck.Helper el: container, mainAttr: '', parent: new Neck.Controller

        pairs = [
          {
            in: "true;false + this.something('asd').else"
            out: "true;false + this.something('asd').else"
            listeners: []
            triggers: []
          }
          {
            in: "one.two.three"
            out: "scope.one.two.three"  
            listeners: [
              "one"
              "one.two"
              "one.two.three"
            ]
            triggers: [
              "one.two.three"
            ]
          }
          { 
            in: "some + other['something().asd'].other() + 'dsa'"
            out: "scope.some + scope.other['something().asd'].other() + 'dsa'" 
            listeners: [
              "some"
              "other"
              "other['something().asd']"
              "other['something().asd'].other"
            ]
            triggers: [
              "some"
              "other['something().asd'].other"
            ]
          }
          {
            in: "{property: some == 'asd'}"
            out: "{property: scope.some == 'asd'}"
            listeners: ["some"]
            triggers: ["some"]
          }
          {
            in: "{  property  : some == 'asd' }"
            out: "{  property  : scope.some == 'asd' }"
            listeners: ["some"]
            triggers: ["some"]
          }
          {
            in: "some[other + else[elseTwo]].method(true)"
            out: "scope.some[scope.other + scope.else[scope.elseTwo]].method(true)"
            listeners: ["some", "some[other + else[elseTwo]]", "some[other + else[elseTwo]].method", "other", "else", "else[elseTwo]", "elseTwo"]
            triggers: ["some[other + else[elseTwo]].method", "other", "else[elseTwo]", "elseTwo"]
          }
          {
            in: "some ? 'asd' : otherMethod()"
            out: "scope.some ? 'asd' : scope.otherMethod()"
            listeners: ['some', 'otherMethod']
            triggers: ['some', 'otherMethod']
          }
          {
            in: "some ? one.two : otherMethod()"
            out: "scope.some ? scope.one.two : scope.otherMethod()"
            listeners: ['some', 'one', 'one.two', 'otherMethod']
            triggers: ['some', 'one.two', 'otherMethod']
          }
          {
            in: "@controllerMethod()"
            out: "scope._context.controllerMethod()"
            listeners: []
            triggers: []
          }
        ]

        for pair in pairs
          listeners = []
          triggers = []
          
          out = h._parseEvaluate(pair.in, listeners, triggers)

          assert.equal out, pair.out
          assert.deepEqual listeners, pair.listeners
          assert.deepEqual triggers, pair.triggers
          

    describe "helper methods", ->

      it "should create property chain", ->
        text = "one.two.three"
        chain = Neck.Helper.prototype._propertyChain text
        assert.deepEqual chain, ["one", "one.two", "one.two.three"] 

        text = "one['asd'].two.three"
        chain = Neck.Helper.prototype._propertyChain text
        assert.deepEqual chain, ["one", "one['asd']", "one['asd'].two", "one['asd'].two.three"] 

      it "should chreate object chain", ->
        c = new Neck.Controller()
        Neck.Helper.prototype._createObjectChain c.scope, "one.two.three"
        assert.deepEqual c.scope.one, two: three: undefined

        # Don't change values set already
        c = new Neck.Controller()
        c.scope.one = two: three: 'asd'
        Neck.Helper.prototype._createObjectChain c.scope, "one.two.three"
        assert.deepEqual c.scope.one, two: three: 'asd'

        # Throw error for chaining not set array
        c = new Neck.Controller()
        assert.throw ->
          Neck.Helper.prototype._createObjectChain c.scope, "one['asd'].two.three"

        # Return for chaining set array
        c = new Neck.Controller()
        c.scope.one = []
        Neck.Helper.prototype._createObjectChain c.scope, "one[1].two.three"
        assert.deepEqual c.scope.one, []
    
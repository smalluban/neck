describe 'Tools', ->

  describe "'dashToCamel' method", ->

    it 'should transform string properly', ->
      assert.equal Neck.Tools.dashToCamel("some-dash-thing"), "someDashThing"

  describe "'camelToDash' method", ->

    it 'should transform string properly', ->
      assert.equal Neck.Tools.camelToDash("someCamelThing"), "some-camel-thing"

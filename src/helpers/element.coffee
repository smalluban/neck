class Neck.Helper.element extends Neck.Helper

  constructor: ->
    super
    throw "'ui-element' attribute has to be string" unless typeof @scope._main is 'string'

    @parent?.scope[@scope._main] = @$el
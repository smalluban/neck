class Neck.Helper.template extends Neck.Helper

  constructor: ->
    super

    @scope._main = @$el.html()
    @$el.addClass 'ui-hide'
    
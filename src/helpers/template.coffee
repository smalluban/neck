class Neck.Helper.template extends Neck.Helper
  template: true

  constructor: ->
    super

    @scope._main = @template

    # Clear element
    @$el.addClass 'ui-hide'
    setTimeout => @remove()
      
   
    
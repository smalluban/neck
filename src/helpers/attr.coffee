class Neck.Helper.attr extends Neck.Helper

  constructor: ->
    super
    throw "'ui-attr' attribute has to be object" unless typeof @scope._main is 'object'

    @watch '_main', (main)->
      for key, value of main
        if returnedValue = value
          @$el.attr key, if returnedValue is true then key else returnedValue
        else
          @$el.removeAttr key
      undefined
class Neck.Helper.class extends Neck.Helper

  constructor: ->
    super
    throw "'ui-class' attribute has to be object" unless typeof @scope._main is 'object'

    @watch '_main', (main)->
      for key, value of main
        if value
          @$el.addClass key
        else
          @$el.removeClass key
      undefined
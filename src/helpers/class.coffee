class Neck.Helper.class extends Neck.Helper

  constructor: ->
    super

    throw "'ui-class' attribute has to be object" unless typeof @scope._main is 'object'

    # IE9 bug-fix: Changing attributes array of node while iterating error
    @listenToOnce @parent, 'render:after', ->
      @watch '_main', (main)->
        for key, value of main
          if value
            @$el.addClass key
          else
            @$el.removeClass key
        undefined
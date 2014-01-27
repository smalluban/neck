class Neck.Helper.show extends Neck.Helper

  constructor: ->
    super

    @$el.addClass 'ui-hide'

    @watch '_main', (value)->
      if value
        @$el.removeClass 'ui-hide'
      else
        @$el.addClass 'ui-hide'
class Neck.Helper.hide extends Neck.Helper

  constructor: ->
    super

    @watch '_main', (value)->
      if value
        @$el.addClass 'ui-hide'
      else
        @$el.removeClass 'ui-hide'
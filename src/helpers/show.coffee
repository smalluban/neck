class Neck.Helper.show extends Neck.Helper

  constructor: ->
    super

    @$el.addClass 'ui-hide'

    @watch '_main', (value)->
      @$el.toggleClass 'ui-hide', !value

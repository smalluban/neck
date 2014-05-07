class Neck.Helper.hide extends Neck.Helper

  constructor: ->
    super

    @watch '_main', (value)->
      @$el.toggleClass 'ui-hide', value

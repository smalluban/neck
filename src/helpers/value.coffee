class Neck.Helper.value extends Neck.Helper

  constructor: ->
    super

    @watch '_main', (value)->
      @$el.text value or ""
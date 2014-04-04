class Neck.Helper.value extends Neck.Helper

  constructor: ->
    super

    @watch '_main', (value)->
      @$el.text if value is undefined then "" else value
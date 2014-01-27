class Neck.Helper.init extends Neck.Helper

  constructor: ->
    super

    @watch '_main', (main)->
      if typeof @scope._main is 'function'
        @scope._main.call @scope._context
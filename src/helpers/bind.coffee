class Neck.Helper.bind extends Neck.Helper

  NUMBER: /^[0-9]+((\.|\,)?[0-9]+)*$/

  events:
    "keydown" : "update"
    "change"  : "update"
    "search"  : "update"

  isCheckbox: false

  constructor: ->
    super

    if @$el.is(':checkbox')
      @isCheckbox = true

    @watch '_main', (value)->
      unless @_updated
        if @isCheckbox
          @$el.prop 'checked', value
        else
          @$el.val value or ''
      @_updated = false

  calculateValue: (s)->
    if s.match @NUMBER
      Number s.replace(',','.')
    else
      s

  update: ->
    setTimeout =>
      @_updated = true
      if @isCheckbox
        @scope._main = if @$el.is(':checked') then 1 else 0
      else
        @scope._main = @calculateValue @$el.val()
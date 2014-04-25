class Neck.Helper.bind extends Neck.Helper
  attributes: [
    'bindProperty'
  ]

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

    @watch '_main', ->
      if @scope._main instanceof Backbone.Model 
        throw 'Backbone.Model property required' unless @scope.bindProperty
        throw 'Property has to be a string' unless typeof @scope.bindProperty is 'string'

      unless @_updated
        if @isCheckbox
          @$el.prop 'checked', @getValue()
        else
          @$el.val @getValue() or ''
      @_updated = false

  calculateValue: (s)->
    if s.match @NUMBER
      Number s.replace(',','.')
    else
      s

  update: ->
    setTimeout =>
      # Exit timeout when controller is already destroy
      return unless @scope

      if @isCheckbox
        @setValue if @$el.is(':checked') then 1 else 0
      else
        @setValue @calculateValue @$el.val()

  getValue: ->
    if @scope._main instanceof Backbone.Model
      @scope._main.get(@scope.bindProperty)
    else
      @scope._main

  setValue: (value)->
    @_updated = true
    
    if @scope._main instanceof Backbone.Model
      @scope._main.set @scope.bindProperty, value
    else
      @scope._main = value 
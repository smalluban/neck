class Neck.Helper.bind extends Neck.Helper
  attributes: [
    'bindProperty'
    'bindNumber'
  ]

  NUMBER: /^[0-9]+((\.|\,)?[0-9]+)*$/

  isCheckbox: false
  isInput: false

  constructor: (opts)->
    super

    @scope.bindNumber = true if @scope.bindNumber is undefined

    if @$el.is('input, textarea, select')
      @isInput = true
      @isCheckbox = true if @$el.is(':checkbox')
    
    @$el.on 'keydown change search', @updateValue

    @watch '_main', (value)->
      if value instanceof Backbone.Model 
        throw "Using Backbone.Model in 'ui-bind' requires 'bind-property'" unless @scope.bindProperty
        throw "'bind-property' has to be a string" unless typeof @scope.bindProperty is 'string'
        return if @model is value
        @stopListening @model if @model
        @model = value
        @listenTo @model, "change:#{@scope.bindProperty}", @updateView
        @updateView()
      else
        if @model
          @stopListening @model
          @model = undefined

        @updateView()
      
  updateView: =>
    unless @isUpdated
      value = if @model then @model.get(@scope.bindProperty) else @scope._main
      if @isCheckbox
        @$el.prop 'checked', !!value
      else
        value = if value is undefined then "" else value
        if @isInput then @$el.val(value) else @$el.html(value)

    @isUpdated = false

  setValue: (value)->
    @isUpdated = true
    
    if @model
      @scope._main.set @scope.bindProperty, value
    else
      @scope._main = value 

  calculateValue: (s)->
    if s.match(@NUMBER) and @scope.bindNumber
      Number s.replace(',','.')
    else
      s

  updateValue: =>
    setTimeout =>
      # Exit timeout when controller is already destroy
      return unless @scope

      if @isInput
        if @isCheckbox
          @setValue if @$el.is(':checked') then 1 else 0
        else
          @setValue @calculateValue @$el.val()
      else
        @setValue @calculateValue @$el.html()
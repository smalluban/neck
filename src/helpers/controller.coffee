class Neck.Helper.controller extends Neck.Helper
  template: true
  attributes: ['controllerParams', 'controllerInherit']
  id: null

  constructor: ->
    super

    @watch '_main', (newId)->
      if newId and not (typeof newId is 'string')
        throw "'ui-controller' main accessor has to be string controller ID"

      return if newId is @id

      if @controller
        @controller.$el = $()
        @controller.remove()

      if @id = newId
        Controller = @injector.load @id, type: 'controller'
        @controller = new Controller el: @$el, params: @scope.controllerParams, template: @template or @id, parent: if @scope.controllerInherit then @parent
        
        @controller.scope._context = @controller if @scope.controllerInherit
        @controller.injector = @injector
        @controller.parseSelf = false
        
        @controller.render()


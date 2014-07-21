class Neck.Helper.view extends Neck.Helper
  template: true
  attributes: ['viewParams', 'viewInherit']
  id: null

  constructor: ->
    super

    @watch '_main', (newId)->
      if newId and not (typeof newId is 'string')
        throw "'ui-view' main accessor has to be string controller ID"

      return if newId is @id
      @$el.empty()

      if @view
        @view.$el = $()
        @view.remove()

      if @id = newId
        Controller = @injector.load @id, type: 'controller'
        @view = new Controller el: @$el, params: @scope.viewParams, template: @id, parent: if @scope.viewInherit then @parent
        
        @view.scope._context = @view if @scope.viewInherit
        @view.injector = @injector
        @view.parseSelf = false
        
        @view.render()


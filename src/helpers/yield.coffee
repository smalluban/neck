class Neck.Helper.yield extends Neck.Helper
  attributes: ['yieldView', 'yieldParams', 'yieldReplace', 'yieldInherit']
  template: true
  replace: false

  constructor: ->
    super

    # Properties
    @name = @scope._main or "main"

    # References
    @context = @scope._context
    @list = @context._yieldList or= {}

    if @list[@name]
      throw "There is already yield with '#{@name}' name in App"
    else
      @list[@name] = @

    @listenTo @context, 'render:clear remove:after', =>
      delete @list[@name]

    @replace or= @scope.yieldReplace

    if @scope.yieldView
      @append @scope.yieldView, @scope.yieldParams

  _createController: (controllerPath, params, parent)->
    Controller = @injector.load(controllerPath, type: 'controller')
    controller = new Controller template: "#{controllerPath}", params: params, parent: if @scope.yieldInherit then @context
    controller.injector = @context.injector # Set injector from parent view controller
    controller.scope._context = controller if @scope.yieldInherit
    
    # Inherit yields
    controller._yieldList = Object.create @list
    controller._yieldPath = controllerPath

    # Set parent controller
    parent._yieldChild = controller
    parent.listenTo controller, "remove:after", -> @_yieldChild = undefined
    controller.listenTo parent, "remove:after", -> controller.remove()

    @$el.append controller.render().$el

    controller

  append: (controllerPath, params, refresh = false, replace = @replace)->
    if replace and @_yieldChild
      if controllerPath is @_yieldChild._yieldPath and not refresh
        @_yieldChild._yieldChild?.remove()
      else
        @_yieldChild?.remove()
        @_yieldChild = undefined

    # Check if controller is already in yield
    parent = @
    child = undefined

    while parent._yieldChild
      child = parent._yieldChild
      if child._yieldPath is controllerPath
        if refresh
          child.remove()
          break
        else
          child._yieldChild?.remove()
          child._yieldChild = undefined
          return child

      parent = parent._yieldChild
  
    @_createController controllerPath, params , parent

  clear: ->
    if @_yieldChild
      @_yieldChild.remove()
      @_yieldChild = undefined
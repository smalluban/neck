class Neck.Helper.yield extends Neck.Helper
  attributes: ['yieldView', 'yieldParams', 'yieldReplace', 'yieldInherit', 'yieldHistory']
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
    
    if @scope.yieldHistory
      window.addEventListener "popstate", @_popState
      @on "remove:after", => 
        window.removeEventListener "popstate", @_popState

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
    parent.listenTo controller, "remove:after", =>
      @_backHistory parent
      parent._yieldChild = undefined

    controller.listenTo parent, "remove:after", -> controller.remove()

    @$el.append controller.render().$el

    controller

  _popState: ()=>
    if @omitPop
      @omitPop = false
      return

    controllerPath = history.state
    parent = @
    child = undefined

    while parent._yieldChild
      child = parent._yieldChild
      if child._yieldPath is controllerPath
        @omitBack = true
        child._yieldChild?.remove()
        break
      parent = child

  _pushHistory: (controllerPath, actionName)->
    return if not @scope.yieldHistory
    history[actionName](controllerPath, '', undefined)

  _backHistory: (child)->
    return if not @scope.yieldHistory

    if @omitBack
      @omitBack = false
      return

    deep = 0
    while child._yieldChild
      deep += 1
      child = child._yieldChild
    
    @omitPop = true
    history.back(deep)

  append: (controllerPath, params, refresh = false, replace = @replace)->
    if replace and @_yieldChild
      if controllerPath is @_yieldChild._yieldPath 
        if @_yieldChild._events["render:refresh"] or not refresh
          @_yieldChild._yieldChild?.remove()
        else
          @_yieldChild.remove()
          @_yieldChild = undefined
      else
        @_yieldChild.remove()
        @_yieldChild = undefined

    historyAction = if not @_yieldChild then 'replaceState' else 'pushState'

    # Check if controller is already in yield
    parent = @
    child = undefined

    while parent._yieldChild
      child = parent._yieldChild
      if child._yieldPath is controllerPath
        if refresh and not child._events["render:refresh"]
          child.remove()
          break
        else
          child.trigger "render:refresh"
          child._yieldChild?.remove()
          child._yieldChild = undefined
          return child

      parent = parent._yieldChild
  
    @_createController controllerPath, params, parent
    @_pushHistory controllerPath, historyAction

  clear: ->
    if @_yieldChild
      @_yieldChild.remove()
      @_yieldChild = undefined
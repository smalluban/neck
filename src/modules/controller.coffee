class Neck.Controller extends Backbone.View 
  # Check reverse parsing 
  @REVERSE_PARSING: $('<div ui-test1 ui-test2></div>')[0].attributes[0].name is 'ui-test2'

  REGEXPS:
    PROPERTY_SEPARATOR: /\.|\[.+\]\./

  divWrapper: true
  parseSelf: true
  template: undefined

  injector: Neck.DI.globals

  constructor: (opts = {})->
    super

    # Create scope inherit or new
    scope = if @parent = opts.parent then Object.create(@parent.scope) else _context: @
    @scope = _.extend scope, @scope, _resolves: {}

    # Listen to parent events
    if @parent
      @listenTo @parent, 'render:before', @remove 
      @listenTo @parent, 'remove:before', @remove

      # Inherit injector
      @injector = @parent.injector
      
    switch @template
      when undefined
        @template = opts.template if opts.template
      when true
        @template = @$el.html()
        @$el.empty()

    @params = opts.params or {}

  remove: =>
    @trigger 'remove:before'

    # Clear references
    @parent = undefined
    @scope = undefined

    # Trigger Backbone remove 
    super

    @trigger 'remove:after'
    undefined

  render: ->
    @trigger 'render:before' 

    @_onRender = true

    if @template
      unless typeof @template is 'function'
        if typeof (template = @injector.load(@template, type: 'template')) is 'function'
          template = template @scope
      else
        template = @template @scope

      @_parseNode @el, true if @parseSelf
  
      template = $(template)
      @_parseNode el for el in template
          
      if @divWrapper
        @$el.html template
      else
        @setElement template
    else
      @_parseNode el for el in unless @parseSelf then @$el.children() else @$el

    if @parent?._onRender
      @listenToOnce @parent, 'render:after', -> @trigger 'render:after'
    else
      setTimeout => @trigger 'render:after'

    @_onRender = false
    @

  _parseNode: (node, stop = false)->
    if node?.attributes
      el = $(node)
      buffer = []
      for attribute in node.attributes
        if attribute.nodeName?.substr(0, 3) is "ui-"
          name = Neck.Tools.dashToCamel attribute.nodeName.substr(3)
          controller = (Neck.Helper[name] or @injector.load(name, type: 'helper'))
          sortHelpers = true if controller.prototype.orderPriority
          buffer.push controller: controller, value: attribute.value

      # Firefox reads attributes in reverse order. 
      # For manually set order use 'orderPriority' in helper
      buffer.reverse() if Neck.Controller.REVERSE_PARSING
      buffer = _.sortBy(buffer, (b)-> - b.controller.prototype.orderPriority ) if sortHelpers

      for item in buffer
        stop = true if item.controller.prototype.template isnt undefined
        new item.controller el: el, parent: @, mainAttr: item.value

    @_parseNode child for child in node.childNodes unless stop or not node
    undefined

  _watch: (key, callback, context = @)->
    shortKey = key.split(@REGEXPS.PROPERTY_SEPARATOR)[0]

    if @scope.hasOwnProperty(shortKey)
      if Object.getOwnPropertyDescriptor(@scope, shortKey)?.get
        return context.listenTo @, "refresh:#{key}", callback
    else
      controller = @
      while controller = controller.parent
        if controller.scope.hasOwnProperty shortKey
          return controller._watch key, callback, context
      undefined

    # Create get/set property for shortKey
    val = @scope[shortKey]

    if val instanceof Backbone.Model
      @listenTo val, "change", => @apply shortKey
    else if val instanceof Backbone.Collection
      @listenTo val, "add remove change", => @apply shortKey

    Object.defineProperty @scope, shortKey, 
      enumerable: true
      get: -> val
      set: (newVal)=>
        if newVal instanceof Backbone.Model
          @stopListening val
          @listenTo newVal, "change", => @apply shortKey
        else if newVal instanceof Backbone.Collection
          @stopListening val
          @listenTo newVal, "add remove change", => @apply shortKey
          
        val = newVal
        @apply shortKey
    
    context.listenTo @, "refresh:#{key}", callback

  _getter: (scope, evaluate, original)->
    try
      getter = new Function "scope", "__return = #{evaluate or undefined}; return __return;"
    catch e
      throw "#{e} in evaluating accessor '#{original or evaluate}'"

    ()-> getter scope

  _setter: (scope, evaluate, original)->
    try
      setter = new Function "scope, __newVal", "return #{evaluate} = __newVal;"
    catch e
      throw "#{e} in evaluating accessor '#{original or evaluate}'"
    
    (newValue)-> setter(scope, newValue)

  watch: (keys, callback, initCall = true)->
    keys = keys.split(' ')
    call = => callback.apply @, _.map keys, (k)=> (@_getter(@scope, "scope.#{k}", k))()

    @_watch key, call for key in keys
    call() if initCall

  apply: (key)->
    unless @scope.hasOwnProperty(key)
      controller = @
      while controller = controller.parent
        if controller.scope.hasOwnProperty(key)
          return controller.trigger "refresh:#{key}"

    @trigger "refresh:#{key}"

  route: (controller, options = {yield: 'main'})->
    throw "No yields list. You may call method from controller custructor?" unless @._yieldList
    throw "No yield '#{options.yield}' for route in yields chain" unless target = @._yieldList[options.yield]
   
    target.append controller, options.params, options.refresh, options.replace

  navigate: (url, params, options = {trigger: true})->
    Neck.Router.prototype.navigate url + (if params then '?' + $.param(params) else ''), options
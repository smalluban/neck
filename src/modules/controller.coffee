class Neck.Controller extends Backbone.View  
  divWrapper: true
  template: false
  parseSelf: true

  injector: Neck.DI.commonjs

  constructor: (opts)->
    super

    # Create scope inherit or new
    scope = if @parent = opts?.parent then Object.create(@parent.scope) else _context: @
    @scope = _.extend scope, @scope, _resolves: {}

    # Listen to parent events
    if @parent
      @listenTo @parent, 'render:clear', @clear
      @listenTo @parent, 'remove:before', @remove

      # Inherit injector
      @injector = @parent.injector
      
    if opts.template and not @template
      @template = opts.template

    if @template is true
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

  clear: =>
    @off()
    @stopListening()
    @trigger 'render:clear'

  render: ->
    @trigger 'render:clear' # Remove childs listings
    @trigger 'render:before' 

    if @template
      unless typeof @template is 'function'
        if typeof (template = @injector.load(@template, type: 'template')) is 'function'
          template = template @scope
      else
        template = template @scope
          
      if @divWrapper
        @$el.html template
      else
        @setElement $(template)
    
    @_parseNode el for el in (if @parseSelf then @$el else @$el.children())

    @trigger 'render:after'
    @

  _parseNode: (node)->
    if node?.attributes
      el = null
      for attribute in node.attributes
        if attribute.nodeName?.substr(0, 3) is "ui-"
          el or= $(node)
          name = Neck.Tools.dashToCamel attribute.nodeName.substr(3)
          helper = new (Neck.Helper[name] or @injector.load(name, type: 'helper'))(el: el, parent: @, mainAttr: attribute.value)
          stop = true if helper.template isnt false
    
    @_parseNode child for child in node.childNodes unless stop or not node
    undefined

  _watch: (key, callback, context = @)->
    if @scope.hasOwnProperty(key)
      if Object.getOwnPropertyDescriptor(@scope, key)?.get
        if @scope._resolves[key]
          for resolve in @scope._resolves[key]
            resolve.controller._watch resolve.key, callback, context
          return
        else
          return context.listenTo @, "refresh:#{key}", callback
    else
      controller = @
      while controller = controller.parent
        if controller.scope.hasOwnProperty key
          return controller._watch key, callback, context
      undefined

    # Default behavior

    val = @scope[key]

    if val instanceof Backbone.Model or val instanceof Backbone.Collection
      @listenTo val, "change", => @apply key

    Object.defineProperty @scope, key, 
      enumerable: true
      get: -> val
      set: (newVal)=>
        if val instanceof Backbone.Model or val instanceof Backbone.Collection
          @stopListening val
        if newVal instanceof Backbone.Model or val instanceof Backbone.Collection  
          @listenTo newVal, "change", => @apply key
          
        val = newVal
        @apply key
  
    context.listenTo @, "refresh:#{key}", callback

  _resolveValue: (model, propertyChain)->
    try
      eval "model." + propertyChain
    catch e
      undefined

  watch: (keys, callback, initCall = true)->
    keys = keys.split(' ')
    call = => callback.apply @, _.map keys, (k)=> @_resolveValue @scope, k

    @_watch key.split('.')[0], call for key in keys
    call() if initCall

  apply: (key)->
    if @scope._resolves[key]
      for resolve in @scope._resolves[key]
        resolve.controller.trigger "refresh:#{resolve.key}"
      undefined
    else
      controller = @
      while controller = controller.parent
        if controller.scope.hasOwnProperty(key)
          return controller.trigger "refresh:#{key}"

      @trigger "refresh:#{key}"

  route: (controller, options = {yield: 'main'})->
    unless target = @._yieldList[options.yield]
      throw "No yield '#{options.yield}' for route in yields chain"
   
    target.append controller, options.params, options.refresh, options.replace

  navigate: (url, params, options = {trigger: true})->
    Neck.Router.prototype.navigate url + (if params then '?' + $.param(params) else ''), options
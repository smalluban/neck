window.Neck = Neck = {}

# Add "ui-hide" class
$('''
  <style media="screen">
    .ui-hide { display: none !important }
  </style>
  ''').appendTo $('head')

Neck.Tools =
  dashToCamel: (str)-> str.replace /\W+(.)/g, (x, chr)-> chr.toUpperCase()
  camelToDash: (str)-> str.replace(/\W+/g, '-').replace(/([a-z\d])([A-Z])/g, '$1-$2')

Neck.DI =
  controllerPrefix: 'controllers'
  helperPrefix: 'helpers'
  templatePrefix: 'templates'

  _routePath: /^([a-zA-Z$_\.]+\/?)+$/i

  load: (route, options)-> 
    if route.match @_routePath
      try
        return require (if options.type then @[options.type + 'Prefix'] + "/" else '') + route
      catch
        try
          if destiny = eval(route)
            return destiny
          else
            if options.type isnt 'template'
              return throw "No defined '#{route}' object for Neck dependency injection"
        catch
          if options.type isnt 'template'
            return throw "No defined '#{route}' object for Neck dependency injection"

    route

class Neck.Controller extends Backbone.View  
  REGEXPS:
    TEXTS: /\'[^\']+\'/g
    RESERVED_KEYWORDS: /(^|\ )(true|false|undefined|null|NaN|window)($|\.|\ )/g
    SCOPE_PROPERTIES: /([a-zA-Z$_\@][^\ \[\]\:\(\)\{\}]*)/g
    TWICE_SCOPE: /((window|scope)\.[^\ ]*\.)scope\./
    OBJECT: /^\{.+\}$/g
    ONLY_PROPERTY: /^[a-zA-Z$_][^\ \(\)\{\}\:]*$/g

  divWrapper: true
  template: false
  parseSelf: true

  constructor: (opts)->
    super

    # Create scope inherit or new
    scope = if @parent = opts?.parent then Object.create(@parent.scope) else _context: @
    @scope = _.extend scope, @scope, _resolves: {}

    # Listen to parent events
    if @parent
      @listenTo @parent, 'render:clear', @clear
      @listenTo @parent, 'remove:before', @remove
      
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
        if typeof (template = Neck.DI.load(@template, type: 'template')) is 'function'
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
          helper = new (Neck.Helper[name] or Neck.DI.load(name, type: 'helper'))(el: el, parent: @, mainAttr: attribute.value)
          stop = true if helper.template isnt false
    
    @_parseNode child for child in node.childNodes unless stop or not node
    undefined

  _parseValue: (s)->
    s = s.trim()
    texts = []
    resolves = []

    # Replace texts for recognition
    s = s.replace @REGEXPS.TEXTS, (t)-> 
      texts.push t
      "###"

    # Find scope properties
    s = s.replace @REGEXPS.SCOPE_PROPERTIES, (t)=>
      unless t.match @REGEXPS.RESERVED_KEYWORDS
        unless t.substr(0, 1) is '@'
          resolves.push t.split('.')[0]
        else
          t = '_context.' + t.substr(1)
        "scope.#{t}"
      else
        t

    # Clear twice 'scope'
    while s.match @REGEXPS.TWICE_SCOPE
      s = s.replace @REGEXPS.TWICE_SCOPE, "$1"
 
    # Unreplace texts
    if texts.length
      s = s.replace(/###/g, ()-> texts.shift()) 

    [s, _.uniq resolves]

  _setAccessor: (key, value)->
    scope = @parent.scope
    [value, resolves] = @_parseValue value

    options = enumerable: true, get: -> 
      try
        eval value
      catch e
        undefined

    if value.match @REGEXPS.ONLY_PROPERTY
      options.set = (newVal)=>
        model = value.split('.')
        property = model.pop()
        
        # Create objects when they are undefined
        obj = scope
        for m in model.slice(1)
          obj = obj[m] = {} unless obj[m]

        try
          (eval model.join('.'))[property] = newVal
          @apply key if model.length > 1
        catch e
          undefined
    else if value.match @REGEXPS.OBJECT
      value = "(#{value})"
    else 
      options.get = =>
        try
          eval value
        catch e
          undefined
    
    Object.defineProperty @scope, key, options

    @scope._resolves[key] = []
    for resolve in resolves
      if @parent.scope._resolves[resolve]
        @scope._resolves[key] = _.union @scope._resolves[key], @parent.scope._resolves[resolve]
      else
        @scope._resolves[key].push { controller: @parent, key: resolve }
    
    # Clear when empty
    unless @scope._resolves[key].length
      @scope._resolves[key] = undefined

  _watch: (key, callback, context = @)->
    if @scope.hasOwnProperty(key) or !@parent
      if Object.getOwnPropertyDescriptor(@scope, key)?.get
        if @scope._resolves[key]
          for resolve in @scope._resolves[key]
            resolve.controller._watch resolve.key, callback, context
          undefined
        else
          context.listenTo @, "refresh:#{key}", callback
      else
        val = @scope[key]

        if val instanceof Backbone.Model
          @listenTo val, "sync", => @apply key

        Object.defineProperty @scope, key, 
          enumerable: true
          get: -> val
          set: (newVal)=>
            if val instanceof Backbone.Model
              @stopListening val
            if newVal instanceof Backbone.Model  
              @listenTo newVal, "sync", => @apply key
              
            val = newVal
            @apply key
      
        context.listenTo @, "refresh:#{key}", callback
    else
      controller = @
      while controller = controller.parent
        if controller.scope.hasOwnProperty key
          controller._watch key, callback, context
          break
      undefined

  watch: (keys..., callback)->
    call = => callback.apply @, _.map keys, (k)=> @scope[k]
    @_watch key.split('.')[0], call for key in keys
    call()

  apply: (key)->
    if @scope._resolves[key]
      for resolve in @scope._resolves[key]
        resolve.controller.trigger "refresh:#{resolve.key}"
      undefined
    else
      @trigger "refresh:#{key}"

class Neck.Helper extends Neck.Controller
  parseSelf: false

  constructor: (opts)->
    super
    @_setAccessor '_main', opts.mainAttr

    if @attributes
      for attr in @attributes
        if value = @el.attributes[Neck.Tools.camelToDash(attr)]?.value
          @_setAccessor attr, value

class Neck.Router extends Backbone.Router

  PARAM_REGEXP: /\:(\w+)/gi

  constructor:(opts)->
    super

    unless @app = opts?.app
      throw "Neck.Router require connection with App Controller"

  route:(route, settings)->
    myCallback = (args...)=>
      query = {}
      args.pop() if typeof (query = _.last(args)) is 'object'

      if args.length and !_.isRegExp(route)
        route.replace @PARAM_REGEXP, (all, name)->
          query[name] = param if param = args.shift()

      for yieldName, options of (settings.yields or main: controller: settings.controller)
        throw "No '#{yieldName}' yield defined in App" unless @app._yieldList?[yieldName]

        @app._yieldList[yieldName].append (options.controller or options), 
          _.extend({}, options.params, query),
          options.refresh,
          options.replace
          
      @app.scope._state = settings.state if settings.state

    super(route, myCallback)

class Neck.App extends Neck.Controller

  routes: false
  history: pushState: true

  constructor:(opts)->
    super

    if @routes
      @router = new Neck.Router app: @, routes: @routes
      if @history
        @once 'render:after', => Backbone.history.start @history 
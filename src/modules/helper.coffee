class Neck.Helper extends Neck.Controller
  REGEXPS:
    TEXTS: /\'[^\']+\'/g
    RESERVED_KEYWORDS: /(^|\ )(true|false|undefined|null|NaN|window)($|\.|\ )/g
    SCOPE_PROPERTIES: /([a-zA-Z$_\@][^\ \[\]\:\(\)\{\}]*)/g
    TWICE_SCOPE: /((window|scope)\.[^\ ]*\.)scope\./
    OBJECT: /^\{.+\}$/g
    ONLY_PROPERTY: /^[a-zA-Z$_][^\ \(\)\{\}\:]*$/g
    PROPERTY_SETTER: /^scope\.[a-zA-Z$_][^\ \(\)\{\}\:]*(\.[a-zA-Z$_][^\ \(\)\{\}\:]*)+\ *=[^=]/
  
  parseSelf: false

  constructor: (opts)->
    super
    @_setAccessor '_main', opts.mainAttr

    if @attributes
      for attr in @attributes
        if value = @el.attributes[Neck.Tools.camelToDash(attr)]?.value
          @_setAccessor attr, value

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
    cacheVal = ""
    scope = @parent.scope
    [value, resolves] = @_parseValue value

    options = 
      enumerable: true
      get: -> 
        try
          eval value
        catch e
          undefined
      set: (newVal)=>
        cacheVal = newVal
        value = "cacheVal"
        @apply key.split('.')[0]

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
    else if value.match @REGEXPS.PROPERTY_SETTER
      options.get = =>
        try
          eval value
          @apply key
        catch e
          undefined

    Object.defineProperty @scope, key, options

    @scope._resolves[key] = []
    for resolve in resolves
      if @parent.scope._resolves[resolve]
        @scope._resolves[key] = _.union @scope._resolves[key], @parent.scope._resolves[resolve]
      else
        if @parent.parent
          controller = @
          while controller = controller.parent
            if controller.scope.hasOwnProperty(resolve)
              @scope._resolves[key].push { controller: controller, key: resolve }
              break
          unless @scope._resolves[key].length
            @scope._resolves[key].push { controller: @parent, key: resolve }
        else
          @scope._resolves[key].push { controller: @parent, key: resolve }  
    
    # Clear when empty
    unless @scope._resolves[key].length
      @scope._resolves[key] = undefined
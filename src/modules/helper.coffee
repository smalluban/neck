class Neck.Helper extends Neck.Controller
  REGEXPS:
    TEXTS: /\'[^\']+\'/g
    TEXTS_HASHED: /###/g
    FUNCTION: /\(/
    PROPERTIES: /\.?([a-zA-Z$_\@][^\,\ \[\]\:\{\}\(\)]*\(*)/g
    ONLY_PROPERTY: /^[a-zA-Z$_][^\ \(\)\{\}\:]*$/g
    RESERVED_KEYWORDS: /(^|\ )(true|false|undefined|null|NaN|this)($|\.|\ )/g
  
  parseSelf: false
  orderPriority: 0

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
    s = s.replace @REGEXPS.PROPERTIES, (t)=>
      unless (sub = t.substr(0, 1)) is '@' 
        unless sub is '.' or t.match(@REGEXPS.RESERVED_KEYWORDS)
          resolves.push if t.match @REGEXPS.FUNCTION then t.split('.')[0] else t
      else
        t = '_context.' + t.substr(1)
      t
 
    # Unreplace texts
    if texts.length
      s = s.replace @REGEXPS.TEXTS_HASHED, -> texts.shift()

    [s, _.uniq(resolves)]

  _setAccessor: (key, value)->
    strictValue = false
    [value, resolves] = @_parseValue value

    _getter = new Function "__scope", "with (__scope) { __return = #{value or undefined} } return __return"
 
    options = 
      enumerable: true
      get: => 
        try
          return value if strictValue
          _getter.call window, @parent.scope
        catch e
          # console.warn "Getting '#{value}': #{e.message}"
          undefined

    if value.match(@REGEXPS.ONLY_PROPERTY) and !value.match(@REGEXPS.RESERVED_KEYWORDS)
      shortValueKey = value.split('.')[0]
      _setter = new Function "__scope, __newVal", "with (__scope) { return #{value} = __newVal; };"
      options.set = (newVal)=>
        _return = _setter.call window, @parent.scope, newVal
        @parent.apply shortValueKey if shortValueKey isnt value
        _return
    else
      options.set = (newVal)=>
        strictValue = true
        _return = value = newVal
        @apply key
        _return

    Object.defineProperty @scope, key, options

    @scope._resolves[key] = []
    for resolve in resolves
      controller = @
      while controller = controller.parent
        if controller.scope._resolves[resolve]
          @scope._resolves[key] = _.union @scope._resolves[key], @parent.scope._resolves[resolve]
          break
        if controller.scope.hasOwnProperty(resolve.split('.')[0])
          @_addResolver key, controller, resolve
          break
        else unless controller.parent
          @_addResolver key, @parent, resolve 
          
    # Clear when empty
    unless @scope._resolves[key].length
      @scope._resolves[key] = undefined

  _addResolver: (key, controller, resolve)->
    @scope._resolves[key].push controller: controller, key: resolve

    chain = resolve.split('.')
    param = chain.pop()
    obj = controller.scope
    while objName = chain.shift()
      obj[objName] = {} unless obj[objName]
      obj = obj[objName]
    unless obj.hasOwnProperty param
      obj[param] or= undefined # Predefined property if is not set already
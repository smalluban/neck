class Neck.Helper extends Neck.Controller
  REGEXPS:
    TEXTS: /\'[^\']+\'/g
    TEXTS_HASHED: /###/g
    PROPERTIES: /([a-zA-Z$_\@][^\ \[\]\:\(\)\{\}]*)/g
    SETTER: /^[a-zA-Z$_][^\ \(\)\{\}\:]*(\.[a-zA-Z$_][^\ \(\)\{\}\:]*)+\ *=[^=]/
  
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
    getSetter = false

    # Replace texts for recognition
    s = s.replace @REGEXPS.TEXTS, (t)-> 
      texts.push t
      "###"

    # Find scope properties
    s = s.replace @REGEXPS.PROPERTIES, (t)=>
      unless t.substr(0, 1) is '@'
        resolves.push t.split('.')[0]
      else
        t = '_context.' + t.substr(1)
      t

    # Check get setter
    if s.match @REGEXPS.SETTER
      getSetter = true
 
    # Unreplace texts
    if texts.length
      s = s.replace @REGEXPS.TEXTS_HASHED, -> texts.shift()

    [s, _.uniq(resolves), getSetter]

  _setAccessor: (key, value)->
    [value, resolves, getSetter] = @_parseValue value

    _getter = new Function "__scope", "with (__scope) { return #{value}; };"
    _setter = new Function "__scope, __newVal", "with (__scope) { return #{value} = __newVal; };"

    Object.defineProperty @scope, key, 
      enumerable: true
      get: => 
        try
          _return = _getter.call window, @parent.scope
          @apply key if getSetter
          _return
        catch e
          console.warn "Evaluating '#{value}': #{e.message} "
          undefined
      set: (newVal)=>
        _return = _setter.call window, @parent.scope, newVal
        @apply key
        _return

    @scope._resolves[key] = []
    for resolve in resolves
      controller = @
      while controller = controller.parent
        if controller.scope._resolves[resolve]
          @scope._resolves[key] = _.union @scope._resolves[key], @parent.scope._resolves[resolve]
          break
        if controller.scope.hasOwnProperty(resolve)
          @_addResolver key, controller, resolve
          break
        else unless controller.parent
          @_addResolver key, controller, resolve 
          
    # Clear when empty
    unless @scope._resolves[key].length
      @scope._resolves[key] = undefined

  _addResolver: (key, controller, resolve)->
    @scope._resolves[key].push controller: controller, key: resolve
    controller.scope[resolve] or= undefined # Predefined property if is not set already
class Neck.Helper extends Neck.Controller
  REGEXPS: _.extend {}, Neck.Controller::REGEXPS,
    PROPERTIES: /\'[^\']*\'|\"[^"]*\"|(\?\ *)*[\.a-zA-Z$_\@][^\ \'\"\{\}\(\):]*(\ *:)*(\'[^\']*\'|\"[^"]*\")*[^\ \'\"\{\}\(\):]*/g
    ONLY_PROPERTY: /^[a-zA-Z$_][^\ \(\)\{\}\:]*$/g
    RESERVED_KEYWORDS: /(^|\ )(true|false|undefined|null|NaN|void|this)($|[\.\ \;])/g
  
  parseSelf: false
  orderPriority: 0

  constructor: (opts)->
    super
    @_setAccessor '_main', opts.mainAttr

    if @attributes
      for attr in @attributes
        if value = @el.attributes[Neck.Tools.camelToDash(attr)]?.value
          @_setAccessor attr, value

  _propertyChain: (text)->
    chain = []
    part = ''
    inside = false

    for char in text
      if char in ['"',"'"] then inside = !inside
      unless inside then chain.push part if char in ['.', '[']
      part += char

    chain.push part
    chain

  _createObjectChain: (obj, resolve, evaluate)->
    chain = resolve.split('.')
    param = chain.pop()
    while part = chain.shift()
      objName = part.split('[')[0]
      unless obj[objName]
        throw "Array has to be initialized for helper accessor: '#{evaluate}'" if part.match /\[/
        obj[objName] = {}
      return if (obj = obj[objName]) instanceof Array
    unless obj.hasOwnProperty param
      obj[param] or= undefined

  _setAccessor: (key, evaluate)->
    evaluate = evaluate.trim()
    strict = false

    listeners = []
    triggers = []
    parsedEvaluate = evaluate.replace @REGEXPS.PROPERTIES, (t)=>
      unless (char = t.substr(0, 1)) is '@' 
        if not(char in ['"', "'", '.', '?']) and not (t[t.length-1] is ':') and not t.match @REGEXPS.RESERVED_KEYWORDS
          listeners.push.apply listeners, @_propertyChain t
          triggers.push t
          t = 'scope.' + t
        else if char is "?"
          t = t.split(/^\?\ */)[1]
          if not(t[0] in ['"', "'"]) and not t.match @REGEXPS.RESERVED_KEYWORDS
            listeners.push.apply listeners, @_propertyChain t
            triggers.push t
            t = 'scope.' + t
          t = "? " + t
      else
        t = 'scope._context.' + t.substr(1)
      t

    if listeners.length
      triggers = _.uniq triggers
      @scope._resolves[key] = listeners: [], triggers: []
      for chain in _.uniq listeners
        rootKey = chain.split(@REGEXPS.PROPERTY_SEPARATOR)[0]
        controller = @
        while controller = controller.parent
          if controller.scope._resolves[chain]
            @scope._resolves[key].listeners = _.union @scope._resolves[key].listeners, controller.scope._resolves[rootKey].listeners
            @scope._resolves[key].triggers = _.union @scope._resolves[key].triggers, controller.scope._resolves[rootKey].triggers
            break
          if controller.scope.hasOwnProperty(rootKey)
            @scope._resolves[key].listeners.push controller: controller, key: chain
            @scope._resolves[key].triggers.push controller: controller, key: chain if chain in triggers and chain isnt rootKey
            @_createObjectChain controller.scope, chain, evaluate
            break
          else unless controller.parent
            @scope._resolves[key].listeners.push controller: @parent, key: chain
            @scope._resolves[key].triggers.push controller: @parent, key: chain if chain in triggers and chain isnt rootKey
            @_createObjectChain @parent.scope, chain, evaluate

    getter = @_getter(@parent.scope, parsedEvaluate, evaluate)

    options = 
      enumerable: true
      get: -> if strict then parsedEvaluate else getter()

    if parsedEvaluate.match(@REGEXPS.ONLY_PROPERTY) and !parsedEvaluate.match(@REGEXPS.RESERVED_KEYWORDS)
      setter = @_setter(@parent.scope, parsedEvaluate, evaluate)
      options.set = (newVal)=>
        _return = setter newVal
        @apply key
        _return
    else
      options.set = (newVal)=>
        strict = true
        _return = parsedEvaluate = newVal
        @trigger "refresh:#{key}"
        _return

    Object.defineProperty @scope, key, options

  _watch: (key, callback, context = @)->
    if @scope._resolves[key]
      for listen in @scope._resolves[key].listeners
        listen.controller._watch listen.key, callback, context
      undefined
    else 
      super

  apply: (key)->
    if @scope._resolves[key]
      for trigger in @scope._resolves[key].triggers
        trigger.controller.trigger "refresh:#{trigger.key}"
      undefined
    else
      super
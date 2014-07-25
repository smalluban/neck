class Neck.Router extends Backbone.Router

  PARAM_REGEXP: /\:(\w+)/gi

  constructor:(opts)->
    super

    unless @app = opts?.app
      throw "Neck.Router require connection with App Controller"

  _createSettings: (settings)->
    # Mix values to proper structure
    unless settings.yields
      if typeof settings is 'object'
        yields: main: settings
      else if typeof settings is 'string'
        yields: main: controller: settings
      else
        throw "Route structure has to be object or controller name"
    else
      settings

  route:(route, settings)->
    settings = @_createSettings settings

    myCallback = (args...)=>
      if _.isObject (query = _.last(args))
        args.pop() 
      else
        query = {}

      if args.length and !_.isRegExp(route)
        route.replace @PARAM_REGEXP, (all, name)->
          query[name] = param if param = args.shift()

      for yieldName, options of settings.yields
        throw "No '#{yieldName}' yield defined in App" unless _yield = @app._yieldList?[yieldName]
        return _yield.clear() if options is false
        
        _yield.append (options.controller or options), 
          _.extend({}, options.params, query),
          options.refresh,
          options.replace
          
      @app.scope._state = settings.state if settings.state

    super(route, myCallback)
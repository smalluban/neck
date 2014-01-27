class RouteHelper extends Neck.Helper
  attributes: ['routeYield', 'routeReplace', 'routeParams', 'routeRefresh']

  constructor: (opts)->
    super 
    
    opts.e.preventDefault()

    container = @scope.routeYield or 'main'
    
    unless target = @scope._context._yieldList[container]
      throw new Error "No yield '#{container}' for route in yields chain"
   
    target.append @scope._main, @scope.routeParams, @scope.routeRefresh, @scope.routeReplace

class Neck.Helper.route

  constructor: (opts)->
    opts.el.on 'click', (e)->
      new RouteHelper _.extend opts, e: e
class Neck.App extends Neck.Controller

  routes: false
  history: pushState: true

  constructor:(opts)->
    super

    if @routes
      @router = new Neck.Router app: @, routes: @routes
      if @history
        @once 'render:after', => Backbone.history.start @history 
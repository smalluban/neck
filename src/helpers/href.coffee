class HrefHelper extends Neck.Helper
  
  constructor: (opts)->
    super 
    
    opts.e.preventDefault()
    (new Backbone.Router).navigate @scope._main, trigger: true

class Neck.Helper.href

  constructor: (opts)->
    opts.el.on 'click', (e)->
      new HrefHelper _.extend opts, e: e
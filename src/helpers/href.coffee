class HrefHelper extends Neck.Helper
  
  constructor: (opts)->
    super 
    
    opts.e.preventDefault()
    Neck.Router.prototype.navigate @scope._main, trigger: true

class Neck.Helper.href
  constructor: (opts)->
    # Add href for styling purposes
    opts.el.attr 'href', '#'

    opts.el.on 'click', (e)->
      new HrefHelper _.extend opts, e: e
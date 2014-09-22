( ()->
  # ECMAScript 5
  "use strict"

  # Helper functions

  extend = (obj, extend)->
    for property, value of extend
      obj[property] = value unless obj.hasOwnProperty property
    obj

  # Core library
  Neck =
    observers: []
    components: []
    attributePrefix: false

    setup: (el)->
      @observers.push observer = new MutationObserver (mutations)=>
        for mutation in mutations
          for node in mutation.addedNodes
            # compile element components
            @compile node

          for node in mutation.removedNodes
            # remove element components
            @remove node

        return

      observer.observe el, childList: true, subtree: true
      return el

    compile: (el)->
      if node.nodeType is Node.ELEMENT_NODE
        console.dir el

    remove: (el)->
      console.log "Removing el: #{el}"

  document.registerNeckComponent = (target, opts)->
    # Query target

    extend opts,
      priority: 0
      target: target

    # Set flags
    opts.flags = opts.flags.split(' ') if opts.flags

    Neck.components.push options

  # Initialize Neck
  root.addEventListener "DOMContentLoaded", ->
    # Set order of registered components
    Neck.components.sort (a,b)-> b.priority - a.priority

    # Search for starting points - neck attribute
    for el in document.querySelectorAll '[neck]'
      Neck.setup el

)()

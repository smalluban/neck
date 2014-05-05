### LIST OF EVENTS TO TRIGGER ###

EventList = [
  # Mouse events
  "click", "dblclick"
  "mouseenter", "mouseleave", "mouseout"
  "mouseover", "mousedown", "mouseup"
  "drag", "dragstart", "dragenter", "dragleave", "dragover", "dragend", "drop"
  # General
  "load"
  "focus", "focusin", "focusout", "select", "blur"
  "submit"
  "scroll"
  # Touch events
  "touchstart", "touchend", "touchmove", "touchenter", "touchleave", "touchcancel"
  # Keys events
  "keyup", "keydown", "keypress"
]

class EventHelper extends Neck.Helper
  constructor: (opts)->
    super
    
    if typeof @scope._main is 'function'
      @scope._main.call @scope._context, opts.e

    @apply '_main'

    @off()
    @stopListening()

  _resolveKey: (scope, keyChain)->
    keys = keyChain.split('.')
    property = keys.pop()

    while key = keys.shift()
      scope = scope[key]

    [scope, property]

  apply: (key)->
    if @scope?._resolves[key]
      newResolves = []

      # Check if key resolvers are 'self' appliers
      for resolve, index in @scope._resolves[key]
        [obj, key] = @_resolveKey resolve.controller.scope, resolve.key
        unless Object.getOwnPropertyDescriptor(obj, key)?.get
          newResolves.push resolve

      if newResolves.length
        @scope._resolves[key] = newResolves
        super

class Event
  template: false
  
  constructor: (options)->
    # Anchor should have 'href' attribute
    if options.el[0].tagName is 'A'
      options.el.attr 'href', '#' unless options.el.attr 'href'

    options.el.on @eventType, (e)=>
      e.preventDefault()
      options.e = e
      new EventHelper options

for ev in EventList
  helper = class ER extends Event
  helper::eventType = ev
  Neck.Helper[Neck.Tools.dashToCamel("event-#{ev}")] = helper
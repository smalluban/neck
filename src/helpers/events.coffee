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
    
    if typeof (method = @scope._main) is 'function'
      method.call @scope._context, opts.e

    # When action call @remove method scope is cleared
    # Then apply method should not be called
    if @scope
      @apply '_main' 
      @off()
      @stopListening()

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
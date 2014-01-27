$ ->
  $('[ui-neck]').each ->
    el = $(@)
    name = eval(el.attr('ui-neck'))
    Controller = Neck.DI.load(name, type: 'controller')

    el.removeAttr 'ui-neck'
    (new Controller(el: el)).render()
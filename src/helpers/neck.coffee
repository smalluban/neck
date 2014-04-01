$ ->
  $('[ui-neck]').each ->
    el = $(@)
    name = eval(el.attr('ui-neck'))
    injector = Neck.DI[ if el.attr('neck-injector') then eval(el.attr('neck-injector')) else 'globals' ]
    Controller = injector.load(name, type: 'controller')

    el.removeAttr 'ui-neck'
    controller = new Controller(el: el)
    controller.injector = injector
    controller.render()
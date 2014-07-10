class Neck.Helper.list extends Neck.Helper
  # Item Controller
  class @ItemController extends Neck.Controller
    divWrapper: false

    constructor: (opts)->
      super

      @item = opts.item
      
      # Set own property
      Object.defineProperty @scope, opts.itemName,
        enumerable: true
        writable: true
        configurable: true
        value: opts.item

      # For iterating number in view
      @scope._index = opts.index

  attributes: [
    'listItem',
    'listSort',
    'listFilter',
    'listView',
    'listEmpty',
    'listController'
  ]

  template: true
  itemController: @ItemController

  constructor: ->
    super

    @itemTemplate = @template
    @itemTemplate = @scope.listView if @scope.listView
    @template = @scope.listEmpty

    if controller = @scope.listController
      if typeof controller is 'string'
        @itemController = @injector.load(controller, type: 'controller')
      else
        @itemController = controller

    @itemName or= 'item'
    @items = []

    @watch '_main', (@list)->
      if @list and not (@list instanceof Array)
        throw "'ui-list' main accessor has to be Array instance"

      @resetItems()
      @apply 'listSort' if @scope.listSort 
      @apply 'listFilter' if @scope.listFilter

    @watch 'listSort', (sort)->
      if sort and @list
        @list = _.sortBy @list, (i)-> sort(i)
        for item in @list
          _.findWhere(@items, item: item).$el.appendTo @$el
        undefined

    @watch 'listFilter', (filter)->
      if filter or filter is ""
        for i in @items
          if (item.model + "").toLowerCase().match filter.toLowerCase()
            i.$el.removeClass 'ui-hide'
          else
            i.$el.addClass 'ui-hide'
        undefined

  resetItems: ->
    item.remove() for item in @items
    @items = []
    @$el.empty()

    if @list?.length
      @add(item) for item in @list
      undefined
    else if @scope.listEmpty and @template
      @render()

  add: (item)->
    @items.push item = new @itemController(
      template: @itemTemplate
      parent: @
      item: item
      itemName: @itemName
      index: @items.length
    )
    @$el.append item.render().$el
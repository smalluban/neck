class Neck.Helper.list extends Neck.Helper
  attributes: ['listItem', 'listSort', 'listFilter', 'listView']
  template: true

  constructor: ->
    super

    unless @scope._main instanceof Array
      return new Error "Given object has to be instance of Array"

    @template = @scope.listView if @scope.listView
    @itemName or= 'item'
    @items = []

    @watch '_main', (@list)->
      @resetItems()

      @apply 'listSort' if @scope.listSort 
      @apply 'listFilter' if @scope.listFilter

    @watch 'listSort', (sort)->
      if sort
        @list = _.sortBy @list, (i)-> sort(i)
        for item in @list
          _.findWhere(@items, item: item).$el.appendTo @$el
        undefined

    @watch 'listFilter', (filter)->
      if filter or filter is ""
        filter = new RegExp filter, "gi"
        for i in @items
          if (i.item + "").match filter
            i.$el.removeClass 'ui-hide'
          else
            i.$el.addClass 'ui-hide'
        undefined

  resetItems: ->
    item.remove() for item in @items
    @items = []

    @add(item) for item in @list
    undefined

  add: (item)->
    @items.push item = new Item(
      template: @template
      parent: @
      item: item
      itemName: @itemName
      index: @items.length
    )
    @$el.append item.render().$el

class Item extends Neck.Controller
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
class Neck.Helper.collectionItem extends Neck.Controller
  divWrapper: false

  constructor: (opts)->
    super

    @model = opts.model
    
    # Set own property
    Object.defineProperty @scope, opts.itemName,
      enumerable: true
      writable: true
      configurable: true
      value: opts.model

    # For iterating number in view
    @scope._index = opts.index
    
    if opts.externalTemplate
      @listenTo @scope[opts.itemName], 'change', => 
        @$el.replaceWith @render().$el

class Neck.Helper.collection extends Neck.Helper
  attributes: [
    'collectionItem',
    'collectionSort',
    'collectionFilter',
    'collectionView',
    'collectionEmpty',
    'collectionController'
  ]

  template: true
  itemController: Neck.Helper.collectionItem

  constructor: ->
    super

    @itemTemplate = @template
    @itemTemplate = @scope.collectionView if @scope.collectionView
    @template = @scope.collectionEmpty

    if controller = @scope.collectionController
      if typeof controller is 'string'
        @itemController = @injector.load(controller, type: 'controller')
      else
        @itemController = controller
    
    @scope.collectionItem or= 'item'
    @items = []

    @watch 'collectionSort', (sort)->
      if sort and @collection
        @collection.comparator = sort
        @collection.sort()

    @watch 'collectionFilter', (filter)->
      if filter or filter is ""
        filter = new RegExp filter, "gi"
        for item in @items
          if (item.model + "").match filter
            item.$el.removeClass 'ui-hide'
          else
            item.$el.addClass 'ui-hide'
        undefined
    
    @watch '_main', (collection)->
      return if collection is @collection or not (collection instanceof Backbone.Collection)
      @stopListening @collection if @collection

      if @collection = collection
        @apply 'collectionSort'
        @apply 'collectionFilter'

        @listenTo @collection, "add", @addItem
        @listenTo @collection, "remove", @removeItem
        @listenTo @collection, "sort", @sortItems
        @listenTo @collection, "reset", @resetItems

      @resetItems()

  addItem: (model)=>
    @$el.empty() unless @items.length

    @items.push item = new @itemController(
      template: @itemTemplate
      externalTemplate: @scope.collectionView
      parent: @parent
      model: model
      itemName: @scope.collectionItem
      index: @items.length
    )
    @$el.append item.render().$el

  removeItem: (model)=>
    item = _.findWhere(@items, model: model)
    @items.splice @items.indexOf(item), 1
    item.remove()

    unless @collection?.length
      @renderEmpty()

  sortItems: =>
    for model in @collection.models
      _.findWhere(@items, model: model).$el.appendTo @$el
    undefined

  resetItems: =>
    item.remove() for item in @items
    @items = []
    @$el.empty()

    if @collection?.length
      @addItem(item) for item in @collection.models
      undefined
    else
      @renderEmpty()

  renderEmpty:->
    @render() if @template
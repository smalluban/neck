# Neck

[![Build Status](https://travis-ci.org/smalluban/neck.svg)](https://travis-ci.org/smalluban/neck) [![Coverage Status](https://coveralls.io/repos/smalluban/neck/badge.png?branch=master)](https://coveralls.io/r/smalluban/neck?branch=master)

Neck is a library that adds number of features to Backbone.js:

* Event driven data-binding between controller and view (no dirty checking)
* Flexible dependeny injection module working with CommonJS out of the box
* Support for any JavaScript template engine
* Over a dozen helpers for view logic:
    * collections/lists management
    * showing/hiding elements
    * triggering events
    * routing (by refrencing and url based) to nested views (working like Android Activity Stack) 
    * and more...


## Overview

Library is inspired (in convention and code) by frameworks [Angular](http://angularjs.org/) and 
[Batman](http://batmanjs.org/). Neck is not separete framework. It extends Backbone.js functionality. 
You can use it with many other plug-ins and libraries created for Backbone.js.

Simple todo application could looks like this:

__Controller__:
```coffeescript
class MyController extends Neck.Controller
  constructor:->
    super
    @scope.models = new Backbone.Collection()
```

__View__:
```jade
div(ui-neck="'MyController'")
  ul(ui-collection="models")
    li
      span(ui-value="item.get('name')")
      button(ui-event-click="item.destroy()") remove

  input(ui-bind="newItemName")
  button(
    ui-event-click="models.add({name: newItemName}); newItemName = ''"
    ui-attr="{ disabled: !newItemName }"
  ) Add todo
```

## Setup

```shell
bower install --save neck
```

Library depends on [Backbone.js](http://backbonejs.org/) and [Underscore.js](http://underscorejs.org/).
They have to be included before Neck. 

```html
<script src="/path/to/underscore.js"></script>
<script src="/path/to/backbone.js"></script>
<script src="/path/to/neck.js"></script>
```

## Browser support

* Current version of all modern browsers, IE9+

## Project skeleton

To take full potencial of Neck, You should use it with CoffeeScript and one of JavaScript template engines. 

I encourge to use [Neck on Brunch](http://github.com/smalluban/neck-on-brunch) skeleton, which can be great
starting point for working with Neck. It includes tools like Brunch building tool, CommonJS, CoffeeScript, 
Stylus and Jade. It is working example of simple Neck application.

## API Documentation

- [Neck.Controller](#neckcontroller)
    - [Initializing](#initializing)
    - [Instance properties](#instance-properties)
        - [scope](#scope-controllerscope)
        - [parent](#parent-controllerparent-default-undefined)
        - [params](#params-controllerparams-default-undefined)
        - [template](#template-controllertemplate-default-undefined)
        - [divWrapper](#divwrapper-controllerdivwrapper-default-true)
        - [parseSelf](#parseself-controllerparseself-default-true)
        - [injector](#injector-controllerinjector-default-neckdiglobals)
    - [Instance methods](#instance-methods)
        - [constructor](#constructor-new-neckcontrollerparams)
        - [render](#render-controllerrender)
        - [watch](#watch-controllerwatchkeys-callback-initcall)
        - [apply](#apply-controllerapplykey)
- [Neck.Helper](#neckhelper)
    - [Initializing](#initializing)
    - [Understanding accessors](#understanding-accessors)
    - [Power of universal interpreting](#power-of-universal-interpreting)
    - [Mapping accessors](#mapping-accessors)
    - [Helper with template](#helper-with-template)
    - [Instance properties](#instance-properties)
        - [attributes](#attributes-helperattributes-default-undefined)
        - [orderPriority](#orderpriority-helperorderpriority-default-0)
- [Neck.App](#neckapp)
    - [Instance properties](#instance-properties)
        - [routes](#routes-approutes-default-false)
        - [history](#history-apphistory-default-pushestate-true)
- [Neck.DI](#neckdi)
    - [Neck.DI.globals](#neckdiglobals)
    - [Neck.DI.commonjs](#neckdicommonjs)
- [Built-in helpers](#built-in-helpers)
    - [ui-attr](#ui-attr)
    - [ui-bind & ui-value](#ui-bind--ui-value)
    - [ui-class](#ui-class)
    - [ui-collection](#ui-collection)
    - [ui-element](#ui-element)
    - [ui-event-...](#ui-event-)
    - [ui-hide & ui-show](#ui-hide--ui-show)
    - [ui-href](#ui-href)
    - [ui-init](#ui-init)
    - [ui-list](#ui-list)
    - [ui-neck](#ui-neck)
    - [ui-route](#ui-route)
    - [ui-template](#ui-template)
    - [ui-yield](#ui-yield)

## Neck.Controller

Extends `Backbone.View`, controls data passed to template. It can be also container for callback actions 
from view (Initialized template with controller is called as a view).

### Initializing

`Neck.Controller` can be initialized directly or by `ui-neck` helper (read `ui-neck` [section](#ui-neck)): 

```coffeescript
class MyController extends Neck.Controller
  template: 'myControllerTemplate'
  constructor:->
    super
    # Your setup actions
    @$el.addClass 'myController'

myController = (new MyController el: $('#myElement')).render()
```

When you initialize controller directly, you have to call `render` method to start parsing process and connect
template to controller `el` object.

### Instance properties

#### scope `controller.scope` 

Everything that you set inside `scope` property will be available in a view.

```coffeescript
class MyController extends Neck.Controller
  constructor:->
    super
    @scope.property = 'Some text'
    @scope.something = 'Some other text'
```

```jade
h1 My View
p!= property
ul
  li!= something
  li(ui-value="something")
```

You can use `scope` properties directly and put them in template (they will refresh on every `render` call), 
or put them into `helpers` using accessors.

`scope` is passed as first argument to templating function. Many templating engines use passed object as context (like Jade). Then `scope` properties can be accessed by thier name directly.

Properties can be predefined (you can omit `constructor` method):

```coffeescript
class MyController extends Neck.Controller
  scope:
    property: 'first property text'

  someAction: ->
    console.log @scope.property # Will write 'first property text'
```

`scope` has special `_context` and `_resolves` properties. They should not be touched or used directly.

#### parent `controller.parent` (_default: `undefined`_)

Controller can be initialized with `parent` parameter which should points to other `Neck.Controller` instance:

```coffeescript
myController = new Neck.Controller parent: ohterController
```

Child controller inherits `scope` property from parent (as its `prototype`). Then child controller will 
have access to parent `scope` properties by prototype chain (This is used by helpers that inherits scope from main controller).

#### params `controller.params` (_default: `undefined`_)

Use it to safely pass arguments from one controller to another.

For example:

```coffeescript
myController =  new Neck.Controller(params: myParam: 'some text')
```

Consider using `params` with higher priority than inheriting `scope`. Passing params to 
controller is safer and more useful. For example you can create generic contollers 
that react to given params.

Params are not pushed to `scope` property. There is no `scope.params` in controller. 
If you want to some param to be in view, You have to set it in `scope` when initializing controller:

```coffeescript
class myController extends Neck.Controller
  constructor:->
    super
    @scope.myProperty = @params.passedObject
```

#### template `controller.template` (_default: `undefined`_)

Property used for rendering body of view. Expected values:

* `string`: id or template body for dependency injector (read Neck.DI [section](#neckdi)). Injector should return 
  `function` (as `function` value below) or `string` containing template.
* `boolean`: When set to `false` controller `el` body will be used as template but not removed from DOM. When set to `true` 
  DOM tree is empty before rendering. This is important for example when helper will reuse own 
  body to create list of elements (read ui-collection or ui-list sections).
* `function`: Set with `controller.scope` property as first argument. Should return `string` value 
  containg template body 

When is not set (default `undefined` value) template is not used, but can be overwritten by options pushed to `constructor` method: 

```coffeescript
# This will work. template will be set to 'myTemplatePath'
myController = new Neck.Controller template: 'myTemplatePath'

class Controller extends Neck.Controller
  template: 'myWorkingTempalatePath' # can be also false / true / templateBody[string]

# This won't change template, and it still will be 'myWorkingTemplatePath'
myController = new Controller tempalte: 'myTemplatePath'
```

Some helpers use this functionality to automatically connects controller with corresponding view (RoR way).
Initializing controller with set `template` param will point the same path for view as for controller 
(but with `template` type for `Neck.DI`).

#### divWrapper `controller.divWrapper` (_default: `true`_)

Controller `el` object (read `Backbone.View` docs) for default is created as empty `div`. Template will be 
placed inside this `div` element. `divWrapper` gives you option to change this behavior. If it is set to `false`, 
`el` object will be replaced by view and appended to DOM without `div` wrapper.

#### parseSelf `controller.parseSelf` (_default: `true`_)

It sets parsing view starting point. Parsing can be started from root node (when set to `true`) or from direct 
children of root node (when set to `false`).

#### injector `controller.injector` (_default: `Neck.DI.globals`_)

Injector property sets which dependency injector object is used when fetching controllers, helpers and templates. 
This property is inherited by controllers and helpers through whole application. You do not need to set it in every 
controller/helper, only root controller should have this property set. If You initialize application by helpers, 
You do not have to set it at all directly in controller.

### Instance methods

#### constructor `new Neck.Controller(params)`

Constructor method reads pushed `params` object and use properties: `parent`, `params`, `template` and all that use 
`Backbone.View` (like `el` property). 

They are used to set instance properites. Other properties from given object are ignored.

#### render `controller.render()`

Method fetches template with `scope` property, executes template function, parses view for helpers and pushes it to 
`el` controller. This method usually do not have to be called directly. For example [ui-yield](#uiyield) call `render` 
after creating new view. However, if you have to refresh view, you can call `render` method from controller. 

This method provides two public events: `render:before` and `render:after`. After render event is triggered when view 
is placed into DOM. This ensures that calling measurement methods will return proper values.

#### watch `controller.watch(keys, callback, initCall)`

Triggers `callback` action when one or more `scope` properties has changed. Expected arguments:

* `keys` [string]: space separated list of evaluating properties of `controller.scope` object
* `callback` [function]: called every time when one of keys has changed; called with all keys as arguments 
  in function, `this` set to `controller` instance where `watch` is set.
* `initCall` [boolean]: Default value: `true`. If set to `false` your callback will not be triggered when 
  watching is initialized.

For `Backbone.Model` method listen also to `change` event. For `Backbone.Collection` its `add`, 
`remove` and `change` events.

When watch is set first time, that `scope` property is changed to getter/setter property. Then every time 
when value of this property change, callback will be invoked:

```coffeescript
@scope.one = 'Something'
@watch 'one', (value)-> console.log "One now is: #{value}"

# This will trigger callback with new value
@scope.one = 'New thing'
```

Deep properties are not supported. Do not use it with keys set to something like 'one.two.three'. 
This method do not polyfills `Object.observe` method. Changing deep properties directly in controller will not 
trigger callback. For more complex structures use `Backbone.Model` and 'Backbone.Collection`. 
(There is great library [Backbone-relational.js](http://backbonerelational.org/) for models with relations).

Hovewer, helper accessor triggers proper changes on deep properties (thanks to its mapping proccess). 
It is recommended to rely more on helpers than using watching method directly in controller.

#### apply `controller.apply(key)`

Usually called by library, accessors or helpers, but can be called manually to trigger `watch` callback
for scope properties. Should be called with key as `string` containing `contorller.scope` property name.

## Neck.Helper

Extends `Neck.Controller`. Used to create view logic and controller data manipulation.

### Initializing

View of controller (`el` object) is parsed when controller is rendered. Going down in tree, nodes are read 
looking for specific attributes - with `ui-` prefix. Name after prefix is traslated from dashed to camelCase 
and checked, if helper definition exists - firstly in built-in helpers container or when there is no helper - 
pushed to `Neck.DI` with `helper` type.

```jade
div(ui-some-helper="someValue", some-helper-property="'test'")
``` 

On initializing helper, main attribute body is used. Initializer can take also other attributes. To avoid 
duplicates use part after prefix and some name. For example `ui-some-helper` should read other attributes 
like `some-helper-property` or `some-helper-other-thing`. This properites are called accessors.

Helper inherits `scope` from controller. Controller `scope` properties can be accessed from helper `scope`. 

### Understanding accessors

Accesors are automatically pushed to helper `scope`. Main attribute (defining helper) as `scope._main`. 
Other attributes are translated from dashed to camelCase (from `some-helper-property` to `scope.someHelperProperty`).

Attributes body is interpreted as JavaScript code in context of parent controller `scope`. 
This means that `someValue` is translating into `controller.scope.someValue`. Interpreting method is called every 
time accessor value is read or written. Value of accesor is dynamic and depends of actual state of controller `scope`.

As body is interpreted as JavaScript, you can write statements as: `a + b + 'someText'` or `someAction(a + b)`. 
In this example `a` and `b` will be interpreted in controller `scope` context. Also method `someAction` will be called
as `controller.scope.someAction`. 

Not initialized `controller.scope` properties will be set to `undefined` to prevent JavaScript runtime error. 
Deep properties will be set as chain of simple objects with last attribute set as `undefined`. 
For example `one.two.three` if not present in `controller.scope` will be created as `scope.one = { two: { three: undefined }}`.
Creating not initialized properties work onlty for objects. If you use array, it has to be defined in controller.

Complex statements are not supported like: `if (a) { someAction(b)} `. You should understand accessor body as write
or read inline statement. However, you can use `;` line separator to create more than one call. It is useful for action triggers. 
Reading accessors will use returned value form first statement. Also inline conditions are supported, like `a ? b : c`.

Adding special character `@` gives possibility to call controller directly (`@someValue` will be interpreted 
as `controller.someValue`). This is useful to call actions from controller inside helper. In below example will be triggered 
action written directly in controller :

```jade
a(ui-event-click="@controllerAction()")
```

If you want to call some global value, like `window.something` write it with `this.` prefix (`this.something`). 

```jade
span(ui-value="this.moment().fromNow()")
```

### Power of universal interpreting

Helper accessors are always interpreted as JavaScript. If helper require string you can pass variable or statement. 
For example `ui-route` uses main accessor as controller ID, but you can put there `scope`
property that value will be used as controller ID:

```coffeescript
@scope.myRoute = 'someController'
```

```jade
div(ui-route="myRoute", ...)
```

This is general behavior. It will work with any accessor.

### Mapping accessors

Accessor attribute body is scanned for controller's `scope` properties and all are pushed 
to special `scope._resolves` container. When any property changes, refresh event of accessor will be triggered.

```coffeescript
class Helper exteds Neck.Helper
  constructor:->
    super
    @watch '_main', (value)->
      console.log "new value of helper: #{value}"
```
```jade
div(ui-helper="2 + someProperty + one(thirdProperty) + 'otherValue' + secondProperty")
```

In this example `scope._main` depends on `someProperty`, `secondProperty` and `thirdProperty` of `controller.scope`. 
Changing deep properties in called function will not trigger accessor change (root properties has own getter/setter and triggers changes). 
You have to call function with deep property as parameter, for example: `someAction(property.deepProperty)`. 
You can also manually invoke `@apply('property.deepProperty') inside controller method.

Mapping works with deep properites:

```jade
div(ui-helper="someObject.someProperty.otherProperty")
```

In this case mapping will add three properties to be watched: `someObject`, `someObject.someProperty` and 
`someObject.someProperty.otherProperty`. 

Other helper can change this value: `someObject.someProperty.otherProperty = "newValue"` and then 
it will trigger referesh. When other helper or controller will change `someObject` or helper change 
`someObject.someProperty`, it also will trigger refresh on that accessor.

### Helper with template

To avoid problems with changing `orderPriority` and `template` properties on already initialized helper, 
they are taken from helper `prototype`. You have to set them before initializing:

```coffeescript
class MyHelper extends Neck.Helper
  # Good way
  template: true
  orderPriority: 1

  constructor:->
    super

    # Bad way - parsing will take `true` value of `template`
    @template = false
```

Helpers with templates can have own nested helpers. Using `@` in accessor body of all helpers in chain points to root controller.

### Instance properties

#### attributes `helper.attributes` (_default: `undefined`_)

Array containing list of attributes that will be created as accessors of helper. As written above they should be created 
with helper name as prefix (but it is not mandatory). 

```coffeescript
class SuperThing extends Neck.Helper
  attributes: [ 'superThingOne', 'superThingTwo']

  constructor: ->
    super
    console.log @scope.superThingOne, @scope.superThingTwo

```
```jade
div(ui-super-thing="'great stuff'", super-thing-one="'yes'", super-thing-two="'no' + ' or ' + 'yes'")
```

Main attribute (as `scope._main`) is always set, even if `attributes` property is `undefined`.

#### orderPriority `helper.orderPriority` (_default: `0`_)

Helpers are initialized as they are ordered inside node. Chrome and Firefox browsers preserve order of node attributes. 
Unfortunately Internet Explorer does not. If you plan to write mobile apps for Android and iOS you can skip this property.

When `orderProperty` is set to higher value helper will be initialized before other helpers in the same node.

## Neck.App

Extends `Neck.Controller`, adds url routing for navigation. Should be used only once for application, 
usually as root controller. When `App` is initialized, it checks routes and starts `Backbone.history`. 

Routes are connected with yields, created by `ui-yield` helper. 

### Instance properties

#### routes `app.routes` (_default: `false`_)

List of application routes. Routes can be created in different ways:

```coffeescript
class App extends Neck.App
  routes:
    # Without 'yields' - controller points to 'main' yield

    # Shortes way - set as string
    'someUrl': 'someController'

    # Full way - set as object
    # with passed options
    'someUrl/otherUrl':
      controller: 'someController'
      params:
        one: 1
        two: 2
      refresh: false
      replace: false

    # With multi yields, set `yields` container with yields names

    'someUrl/:id':
      yields:
        main:
          controller: 'someController'
        modal: 'otherController'
        extra: false
```

This three ways can be mixed. Setting yield to `false` will clear it when url will be reached. Params will be passed as `controller.params`. 
`refresh` and `replace` properties are described in `ui-yield` [section](#ui-yield).

Routes are passed to `Neck.Router` instance module which extends `Backbone.Router`. It has all functionality 
of its parent as setting url params. Different is with passing params to controller - they are passed as object 
with named parameters from url and query parameters (it is prepared to supports 
[backbone-query-parameters](https://github.com/jhudson8/backbone-query-parameters)):

```coffeescript
# With set url like: '/users/:id' and going to '/users/1?title=asd' 
# will initialize controller with object

@params = 
  id: '1'
  title: 'asd' # Only if you add backbone-query-parameters plugin
```

When route is reached `app.scope._state` is set with actual route name. Sometimes it can be useful to check in what state is application.

#### history `app.history` (_default: `pushestate: true`_)

Options passed to `Backbone.history.start` method. Read `Backbone.history` docs for more information.

## Neck.DI

Container for dependency injection modules. Every time when application needs `controller`, `helper` or `template` 
dependency injection `load` method is called:

```coffeescript
# Loading controller
@injector.load someControllerID, type: 'controller'
```

`load` method should take first argument as ID of fetching object, second arguments is options object. For now library calls
that method with options set to `type: 'controller|helper|template'`.

`Neck` supports out of the box two modules: `Neck.DI.globals` and `Neck.DI.commonjs`. For default `Neck` uses `globals`. 
You can write your own manager (or extends existing) to work with your project setup. When you use `ui-neck` helper put your 
manager into `Neck.DI` container.

### Neck.DI.globals

ID passed to `load` method will be interpreted as global variable path, `someController` will be read as `window.someController`. 
It can be object chain like `someObject.someController`. Using `globals` is very easy - to define something, put it into 
global scope:

```coffeescript
class window.MyController extends Neck.Controller
  ...
```
```jade
div(ui-neck="'MyController'")
```

When template is fetched and it is not found as global variable, ID is used as template body. This gives possibility to 
set `controller.template` as string containing template body.

### Neck.DI.commonjs

This injector works with `CommonJS` module to load dependencies. You have to define your resources in proper way and 
have `require` global method.

Module has three parameters that are added as prefixes to resources paths:

* `controllerPrefix`: [string], default: `controllers` 
* `helperPrefix`: [string], default: `helpers` 
* `templatePrefix`: [string], default: `templates`

If template ID is not a proper path it is interpreted as template body and return without change.

## Built-in helpers

Built-in helpers cover basic logic and data management in view. They work with dynamic data-binding. They react automatically 
to actual state of controller `scope`.

### ui-attr

```jade
div(ui-attr="{ id: someProperty, disabled: inputRead == 'something' }")
```

Set collection of attributes. Main accessor should be a `object` with `key` and `value` pairs. Key name is used 
as attribute name. If value return `true`, key is set with key name (for example: `disabled='disabled'`). 
When value is `false` key is removed from node. In ohter cases key is set with value as `string`.

### ui-bind & ui-value

```jade
// Binding with input interaction
input(ui-bind="someProperty")
// Backbone.Model property binding with input
input(ui-bind="someModel", bind-property="'name'")
// Binding any node with set 'contenteditable'
div(ui-bind="someProperty", contenteditable="true")

// Binding for only pushig value to node
span(ui-bind="someProperty")
```

Two way binding `scope` property or attribute of `Backbone.Model`. Model has be bind 
with set `bind-property` accessor as name of attribute (second example).

Number is translated to `integer` or `float` (works with dot and comma delimiter). Other values are returned as `string`.

Pushing values into input nodes uses `val()` method. Updating other elements (like `div`, `span`) uses `html()` method. 
Then writing `'<span>something</span>'` will show only `'something'` text wrapped in `span` element.

```jade
span(ui-value="someProperty")
```

`ui-value` is simpler version of `ui-bind`. It only listen to changes of accessor and pushes value into node. Also it uses `text()`
method, writing `'<span>something<span>'` will be displayed as it is. Use it if you only want to display value with no interact with user.

### ui-class

```jade
div(ui-class="{ selected: index == 1, moving: someAction(property)}")
```

Set collection of classes. Main accessor should be a `object` with `key` and `value` pairs. Key name is used as class
name added or removed from node depending on logic value of `value`.

### ui-collection

```jade
div(ui-collection="collection" ... )
```

Render `Backbone.Collection` models. Main accessor should points to `Backbone.Collection`. Helper uses accessors:

* `collection-item`: `string`: Name of collection model in `scope` property of item. Default `item`.
* `collection-sort`: `string` or `function`: Variable pushed as collection.comparator. Read `Backbone.Collection` 
  docs for more info.
* `collection-filter`: `string` or `function`: When this attribute is `string`, it is check if `model.toString()` 
  contain this `string`. When its false, `ui-hide` class is added to item. When attribute is `function`, 
  it should return `true` or `false` for given item as argument.
* `collection-view`: `string id`: Used with dependeny injection to load item view.
* `collection-empty`: `string id`: When collection is empty node can be fill in empty template.
* `collection-controller`: `string id`: You can use your own item controller instead `Neck.Helper.collectionItem`.
  This can broke helper functionality. Use it if you really need it. 

Every item has `_index` property pushed to its `scope` which coresponds to collection list index. This property is set once 
at the begining and is not change when collection is sorted or filtered.

#### Item templating

When `collection-view` is not set, body of node is used as item template:

```jade
ul(ui-collection="users")
  li(ui-value="item.get('name')")
```

There is different between using inline template (as node body) and using `collection-view`. Inline template can not have 
own template engine logic (it is invoke once when parent template is rendered). Also you can not use item `scope` 
properties directly:

```jade
ul(ui-collection="users")
  // This will be called when hole ul... is rendered, not when using it for item
  if item.something 
    li(ui-value="item.get('name')")
    li!= item.get('address') // This will not work also
```

For that behavior use `collection-view`. It is separate view with own logic and access to `scope` as normal controller:

```jade
ul(ui-collection="users", collection-view="'myUserViewPath'")
```

```jade
if item.something
  li!= item.get('name')
```

Using inline template, everything is refreshed by helpers (data-binding). Using `collection-view` gives possibility 
to set values directly. Because of that, item view has to be rerender every time model changes. It is better to use with 
external template `scope` properties directly than by helpers (especially avoid `ui-value` and use `= property`). 

It gives big performance boost. Rendering large collection with nested collectons with inline templating 
(using lot of helpers) can slow down painting dramatically. Using `collection-view` you can set item body with `scope` 
properties written directly or with data-binding (using helepers).

### ui-element

```jade
div(ui-element="'myDiv'")
```

```coffeescript
class Controller extends Neck.Controller
  ...
  someCallback: ->
    @scope.myDiv.addClass 'super'
```

Create `jQuery` object of node and put it into `controller.scope`. Main accessor should be `string` name.

### ui-event-...

```jade
// Calling controller callback
div(ui-event-submit="@sendForm(true, false)")

// Simple setting new value of scope.property 
div(ui-event-click="property = 'newValue'")

// Statements can use javascript breaking line to create 
// more complex actions
div(ui-event-blur="setSomething(inputValue); inputValue = 'something'")
```

Trigger proper event by calling action written in main accesor. Type of event is set in name of helper, for example
to trigger `click` event use `ui-event-click` helper. List of implemented events:

* Mouse events: `click`, `dblclick`, `mouseenter`, `mouseleave`, `mouseout`, `mouseover`, `mousedown`, `mouseup`, 
  `drag`, `dragstart`, `dragenter`, `dragleave`, `dragover`, `dragend`, `drop`.
* General events: `load`, `focus`, `focusin`, `focusout`, `select`, `blur`, `submit`, `scroll`.
* Touch events: `touchstart`, `touchend`, `touchmove`, `touchenter`, `touchleave`, `touchcancel`.
* Keys events: `keyup`, `keydown`, `keypress`.

Helper invoke `preventDefault()` method of DOM `event` object. It ensure that for example form will not be submit 
or link will not change url.

#### Understading data-binding

When event is triggered, `apply` method is invoke for releated to main accessor `scope` properties. This close the flow 
of data-binding proccess. Using event helpers to interact with user actions ensure that your application view will react 
to data changes automatically (with deep properties mapping).

#### Using jQuery event object

You can pass reference to function istead of calling it: `ui-event-click="myFunction"`. When helper recognize that main
accessor is a `function`, it will invoke that function passing jQuery event as first argument. Unfortunelly You can not then
pass any other arguments defining event.

Also when you pass function normally, but it returns `function`, that `function` will be treat as explained above (as `function` that
will be called with jQuery event object).

#### Multiply events

Neck does not support using the same halper in one node more than once, as DOM attributes have to be unique. You can use complex actions
or wrap node into other node (events are bubbling):

```jade
div(ui-event-click="...")
  span(ui-event-click="...")
```

### ui-hide & ui-show

```jade
div(ui-show="something == 'great'")
div(ui-hide="something != 'great'")
```

Hides or shows element depends on main accessor logic value. Both helper works similar (with oposite logic) with one 
difference - `ui-hide` hides node before it checks logic value for first time. This ensure that element is hidden 
before it can be seen.

`ui-show` and `ui-hide` (also `ui-collection` and `ui-list` to filter elements) uses global `ui-hide` CSS class, 
that set `display: none !important`. You can overwrite it if you want to this working differently.

### ui-href

```jade
a(ui-href="'someUrl'")
```

Call `Neck.Router.navigate` method when node is clicked. This changes url using routes from application and fill in yields.

Helper adds `href='#'` attribute to anchor nodes if it is not set (for styling purposes).

### ui-init

```jade
div(ui-init="someAction(); someProperty = 123")
```

Action invoked in parsing proccess. This can be usefull to initially set some values in `scope` directly from view.

### ui-list

```jade
div(ui-list="someList", ...)
```

Helper works similar to `ui-collection`, but without events which collection has (adding or removing elements, etc..).
Main accessor should points to `Array` instance. Helper uses accessors:

* `list-item`: `string`: Name of list element in `scope` property of item. Default `item`.
* `list-sort`: `function`: Function called within `_.sortBy` method with element as argument. You can there returned some 
  value that will be used to sort elements.
* `list-filter`: `string` or `function`: When this attribute is `string`, it is check if `item.toString()` 
  contain this `string`. When its false, `ui-hide` class is added to item. When attribute is `function`, 
  it should return `true` or `false` for given item as argument.
* `list-view`: `string id`: Used with dependeny injection to load item view,
* `list-empty`: `string id`: When list is empty node can be fill in empty template.
* `list-controller`: `string id`: You can use your own item controller instead `Neck.Helper.collectionItem`.
  This can broke helper functionality. Use it if you really need it. 

Every item has `_index` property pushed to its `scope` which coresponds to list index. This property is set once 
at the begining and is not change when list is sorted or filtered.

Helper only rerender list when main accessor changes. If you change array element 
or remove it from array, helper will not rerender:

```coffeescript
@scope.someList = ['something']

# Won't change view
@scope.someList[0] = 'newValue'

# Will change view 
@scope.someList = ['one', 'two', 'three']
```

Use this helper for simple list of data. For better data-binding use `ui-collection`.

#### Item templating

Read `ui-collection` corresponding [section](#item-templating).

### ui-neck

```jade
div(ui-neck="'controllerName'", neck-injector="'commonjs'")
```

This helper is not real `Neck.Helper` instance. It is ordinary jQuery method invoke when document is ready. 
For coherence in library, helpers name convention is used here. Main accessor should point to your root controller.

Set `neck-injector` as name of one of dependency injector in `Neck.DI` container that you want to use. It will be 
inherit through all controllers and helpers.

`ui-neck` uses RoR convention to use controller name as path to template. It constructs controller passing `template`
param as controller ID. When controller has not defined `template` property, library will look for template using
controller ID (but with `template` type). This works well with `commonjs` dependency injector. 
With `globals` it will point to the same object and can throw errors.

To avoid reusing helper when controller is render, `ui-neck` attribute is removed from node after initialize.

### ui-route

```jade
a(ui-route="'someController'", route-yield="'main'", route-params="{ item: someItem }" ... )
```

Helper pushes controller to `ui-yield` on click. Main accessor should be `string` controller ID. Helper uses accessors:

* `route-yield`: `string id` : To yield with that id controller will be pushed. When not set, 'main' id will be used.
* `route-params`: `object`: Object passed as `params` property to controller.
* `route-refresh`: `boolean`: Refresh option passed to yield. Read more in `ui-yield` [section](#ui-yield).
* `route-replace`: `boolean`: Replace option passed to yield. Read more in `yi-yield` [section](#ui-yield).

Helper does not work without corresponding `ui-yield` (set with `route-yield`). Routing does not change url either. 
For url routing use `ui-href` and `Neck.App` with set routes. 

### ui-template

```jade
div(ui-template="someTemplate")
  p Empty list

div(ui-collection="collection", collection-empty="someTemplate")
```

Set node html body as `scope` property. Main accessor will be set.

Helper is useful for example for using as empty template for `ui-collection` or `ui-list`. 
Then you do not have to create separate file with empty message, just use property created with `ui-template`.

Node is removed from DOM after helper is initialized. 

### ui-yield

```jade
div(ui-yield="'main'" ... )
```

Container for nested views (in this context view means controller with connected template). Main accessor 
should be `string` unique ID of yield. This ID can be used by `ui-route` and routes in `Neck.App` 
to determinate where view should be pushed. Helper uses accessors:

* `yield-view`: `string id`: Controller ID of initially pushed view to yield
* `yield-params`: `object`: Params passed to controller set by `yield-view` (only for initially view)
* `yield-replace`: `boolean`: Determine if view stack is cleared when new view is pushed
* `yield-inherit`: `boolean`: Determine scope inheriting

#### Yield ID

You can use main accessor without setting ID - `ui-yield=""`. Then `'main'` ID will be used. Identity 
has to be unique through all application views, because yield is searched from view where is trigger (like `ui-route`) 
up to application root view. This gives possibility to change parts of your application flexible from any point. 

ID has to be unique in particular state of application. When view is dismiss you can again use yield with the same ID.

#### Yield view stack

Yield for default do not remove existings views, it appends new one at the end of node. To view only last one (on the top) 
you have to write `css` like this: 

```stylus
[ui-yield] div 
  display none
  &:last-child
    display block
```

Helper works similar to Android Activity Stack. State of your parent view is holded by browser, and when you close children view, 
your parent will be in state that was before. But all views work in background. They still has connected data-binding 
(big stack can slow down application).

If your application is simple, you can use one `ui-yield` and push there your views. Create stack like this: 
list -> show -> edit of some products. When you need some navigation, it can be other `ui-yield` put in root application view 
or other place. Also modal with wizard pages can be separate `ui-yield` that has own views with other yields. 

#### Templating in RoR way

Similar to `ui-neck`, helper uses controller ID as `template` parameter in controller constructor. If you use `Neck.DI.commonjs` 
you can leave template property `undefined` and Neck will search for template in right place for you. 

#### Replace and refresh views

When yield appends view, it searches if that view is already there. It uses controller ID pushed to `ui-route` or set 
in `Neck.App` routes. If this view is in stack, helper cleares all children of it making this view last one in stack.

Use `route-replace`, `replace` routes property or `yield-replace` to clear stack when new view is appended. Property set in `yi-yield` 
have less importance (other properties overrides it). When you call a view that is in stack as root already, it will not refresh it, 
only clear its children if they exists.

Use `route-refresh` or `refresh` routes property to recreate view even it is in yield. Refresh means that view is removed form yield 
and put again (controller is initialized). 

In some cases would be better to invoke some callback when view has to be refreshed (for example when user tirgger back action in browser).
If there is set `render:refresh` event in controller, it will be used instead rebuilding controller.

#### Scope inheriting

Sharing `scope` works separate for all views pushed to yield. `scope` between views in stack is not shared. Each one inherits 
`scope` from parent controller, when `yield-inherit` is set to `true`.

As it is described in scope [section](#scope-controllerscope) inheriting should be used carefully. Use yield inheritance when it is really needed.

## Contribution

Feel free to contribute project. For developing, clone project and run:

```
npm install && bower install
```

Use `npm start` and go to your browser `http://localhost:3333/test/` for checking tests. 

### Pull requests

Write some changes, update tests and do pull request to this repository. Please provide 
proper prefix to your commits: `BUG-FIX`, `TEST`, `DOCS`, `REFACTOR` and `NEW-FUNC`. It will be easier
to create changelog reading meaningful commits.

## License

Neck is released under the [MIT License](https://raw.github.com/smalluban/neck/master/LICENSE)

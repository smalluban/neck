// Opening wrapper 
// Taken from backbonejs library
(function(root, factory) {

  // Set up Neck appropriately for the environment. Start with AMD.
  if (typeof define === 'function' && define.amd) {
    define(['underscore', 'jquery', 'exports'], function(_, $, exports) {
      // Export global even in AMD case in case this script is loaded with
      // others that may still expect a global Neck.
      root.Neck = factory(root, exports, _, $);
    });

  // Next for Node.js or CommonJS. jQuery may not be needed as a module.
  } else if (typeof exports !== 'undefined') {
    var _ = require('underscore');
    factory(root, exports, _);

  // Finally, as a browser global.
  } else {
    root.Neck = factory(root, {}, root._, (root.jQuery || root.Zepto || root.ender || root.$));
  }

}(this, function(root, Neck, _, $) {

;(function() {
$('<style media="screen">\n  .ui-hide { display: none !important }\n</style>').appendTo($('head'));

Neck.Tools = {
  dashToCamel: function(str) {
    return str.replace(/\W+(.)/g, function(x, chr) {
      return chr.toUpperCase();
    });
  },
  camelToDash: function(str) {
    return str.replace(/\W+/g, '-').replace(/([a-z\d])([A-Z])/g, '$1-$2');
  }
};

Neck.DI = {};

Neck.DI.globals = {
  load: function(route, options) {
    var destiny;
    try {
      if (destiny = eval(route)) {
        return destiny;
      } else {
        if (options.type !== 'template') {
          throw "No defined '" + route + "' object in global scope";
        }
      }
    } catch (_error) {
      if (options.type !== 'template') {
        throw "No defined '" + route + "' object in global scope";
      }
    }
    return route;
  }
};

Neck.DI.commonjs = {
  controllerPrefix: 'controllers',
  helperPrefix: 'helpers',
  templatePrefix: 'templates',
  _routePath: /^([a-zA-Z$_\.]+\/?)+$/i,
  load: function(route, options) {
    if (route.match(this._routePath)) {
      try {
        return require((options.type ? this[options.type + 'Prefix'] + "/" : '') + route);
      } catch (_error) {
        if (options.type !== 'template') {
          throw "No defined '" + route + "' object for CommonJS dependency injection";
        }
      }
    }
    return route;
  }
};


})();

;(function() {
var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Controller = (function(_super) {
  __extends(Controller, _super);

  Controller.REVERSE_PARSING = $('<div ui-test1 ui-test2></div>')[0].attributes[0].name === 'ui-test2';

  Controller.prototype.divWrapper = true;

  Controller.prototype.parseSelf = true;

  Controller.prototype.template = void 0;

  Controller.prototype.injector = Neck.DI.globals;

  function Controller(opts) {
    var scope;
    if (opts == null) {
      opts = {};
    }
    this.clear = __bind(this.clear, this);
    this.remove = __bind(this.remove, this);
    Controller.__super__.constructor.apply(this, arguments);
    scope = (this.parent = opts.parent) ? Object.create(this.parent.scope) : {
      _context: this
    };
    this.scope = _.extend(scope, this.scope, {
      _resolves: {}
    });
    if (this.parent) {
      this.listenTo(this.parent, 'render:clear', this.clear);
      this.listenTo(this.parent, 'remove:before', this.remove);
      this.injector = this.parent.injector;
    }
    switch (this.template) {
      case void 0:
        if (opts.template) {
          this.template = opts.template;
        }
        break;
      case true:
        this.template = this.$el.html();
        this.$el.empty();
    }
    this.params = opts.params || {};
  }

  Controller.prototype.remove = function() {
    this.trigger('remove:before');
    this.parent = void 0;
    this.scope = void 0;
    Controller.__super__.remove.apply(this, arguments);
    return this.trigger('remove:after');
  };

  Controller.prototype.clear = function() {
    this.off();
    this.stopListening();
    return this.trigger('render:clear');
  };

  Controller.prototype.render = function() {
    var el, template, _i, _len, _ref;
    this.trigger('render:clear');
    this.trigger('render:before');
    if (this.template) {
      if (typeof this.template !== 'function') {
        if (typeof (template = this.injector.load(this.template, {
          type: 'template'
        })) === 'function') {
          template = template(this.scope);
        }
      } else {
        template = this.template(this.scope);
      }
      if (this.divWrapper) {
        this.$el.html(template);
      } else {
        this.setElement($(template));
      }
    }
    _ref = (this.parseSelf ? this.$el : this.$el.children());
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      el = _ref[_i];
      this._parseNode(el);
    }
    this.trigger('render:after');
    return this;
  };

  Controller.prototype._parseNode = function(node) {
    var attribute, buffer, child, controller, el, item, name, sortHelpers, stop, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2;
    if (node != null ? node.attributes : void 0) {
      el = $(node);
      buffer = [];
      _ref = node.attributes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attribute = _ref[_i];
        if (((_ref1 = attribute.nodeName) != null ? _ref1.substr(0, 3) : void 0) === "ui-") {
          name = Neck.Tools.dashToCamel(attribute.nodeName.substr(3));
          controller = Neck.Helper[name] || this.injector.load(name, {
            type: 'helper'
          });
          if (controller.prototype.orderPriority) {
            sortHelpers = true;
          }
          buffer.push({
            controller: controller,
            value: attribute.value
          });
        }
      }
      if (Neck.Controller.REVERSE_PARSING) {
        buffer.reverse();
      }
      if (sortHelpers) {
        buffer = _.sortBy(buffer, function(b) {
          return -b.controller.prototype.orderPriority;
        });
      }
      for (_j = 0, _len1 = buffer.length; _j < _len1; _j++) {
        item = buffer[_j];
        if (item.controller.prototype.template) {
          stop = true;
        }
        new item.controller({
          el: el,
          parent: this,
          mainAttr: item.value
        });
      }
    }
    if (!(stop || !node)) {
      _ref2 = node.childNodes;
      for (_k = 0, _len2 = _ref2.length; _k < _len2; _k++) {
        child = _ref2[_k];
        this._parseNode(child);
      }
    }
    return void 0;
  };

  Controller.prototype._watch = function(key, callback, context) {
    var controller, resolve, shortKey, val, _i, _len, _ref, _ref1,
      _this = this;
    if (context == null) {
      context = this;
    }
    shortKey = key.split('.')[0];
    if (this.scope._resolves[key]) {
      _ref = this.scope._resolves[key];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        resolve = _ref[_i];
        resolve.controller._watch(resolve.key, callback, context);
      }
      return;
    } else {
      if (this.scope.hasOwnProperty(shortKey)) {
        if ((_ref1 = Object.getOwnPropertyDescriptor(this.scope, shortKey)) != null ? _ref1.get : void 0) {
          if (shortKey !== key) {
            context.listenTo(this, "refresh:" + shortKey, callback);
          }
          return context.listenTo(this, "refresh:" + key, callback);
        }
      } else {
        controller = this;
        while (controller = controller.parent) {
          if (controller.scope.hasOwnProperty(shortKey)) {
            return controller._watch(key, callback, context);
          }
        }
        void 0;
      }
    }
    val = this.scope[shortKey];
    if (val instanceof Backbone.Model) {
      this.listenTo(val, "change", function() {
        return _this.apply(shortKey);
      });
    } else if (val instanceof Backbone.Collection) {
      this.listenTo(val, "add remove change", function() {
        return _this.apply(shortKey);
      });
    }
    Object.defineProperty(this.scope, shortKey, {
      enumerable: true,
      get: function() {
        return val;
      },
      set: function(newVal) {
        if (val instanceof Backbone.Model || val instanceof Backbone.Collection) {
          _this.stopListening(val);
        }
        if (newVal instanceof Backbone.Model) {
          _this.listenTo(newVal, "change", function() {
            return _this.apply(shortKey);
          });
        } else if (val instanceof Backbone.Collection) {
          _this.listenTo(newVal, "add remove change", function() {
            return _this.apply(shortKey);
          });
        }
        val = newVal;
        return _this.apply(shortKey);
      }
    });
    if (shortKey !== key) {
      context.listenTo(this, "refresh:" + shortKey, callback);
    }
    return context.listenTo(this, "refresh:" + key, callback);
  };

  Controller.prototype.watch = function(keys, callback, initCall) {
    var call, key, _i, _len,
      _this = this;
    if (initCall == null) {
      initCall = true;
    }
    keys = keys.split(' ');
    call = function() {
      return callback.apply(_this, _.map(keys, function(k) {
        return (new Function("__scope", "try { with (__scope) { return " + k + "; } } catch(e) { return undefined; }"))(_this.scope, k);
      }));
    };
    for (_i = 0, _len = keys.length; _i < _len; _i++) {
      key = keys[_i];
      this._watch(key, call);
    }
    if (initCall) {
      return call();
    }
  };

  Controller.prototype.apply = function(key) {
    var controller, resolve, _i, _len, _ref;
    if (this.scope._resolves[key]) {
      _ref = this.scope._resolves[key];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        resolve = _ref[_i];
        resolve.controller.trigger("refresh:" + resolve.key);
      }
      return void 0;
    } else {
      controller = this;
      while (controller = controller.parent) {
        if (controller.scope.hasOwnProperty(key)) {
          return controller.trigger("refresh:" + key);
        }
      }
      return this.trigger("refresh:" + key);
    }
  };

  Controller.prototype.route = function(controller, options) {
    var target;
    if (options == null) {
      options = {
        "yield": 'main'
      };
    }
    if (!this._yieldList) {
      throw "No yields list. You may call method from controller custructor?";
    }
    if (!(target = this._yieldList[options["yield"]])) {
      throw "No yield '" + options["yield"] + "' for route in yields chain";
    }
    return target.append(controller, options.params, options.refresh, options.replace);
  };

  Controller.prototype.navigate = function(url, params, options) {
    if (options == null) {
      options = {
        trigger: true
      };
    }
    return Neck.Router.prototype.navigate(url + (params ? '?' + $.param(params) : ''), options);
  };

  return Controller;

})(Backbone.View);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper = (function(_super) {
  __extends(Helper, _super);

  Helper.prototype.REGEXPS = {
    TEXTS: /\'[^\']+\'/g,
    TEXTS_HASHED: /###/g,
    FUNCTION: /\(/,
    PROPERTIES: /\.?([a-zA-Z$_\@][^\,\ \[\]\:\{\}\(\)]*\(*)/g,
    ONLY_PROPERTY: /^[a-zA-Z$_][^\ \(\)\{\}\:]*$/g,
    RESERVED_KEYWORDS: /(^|\ )(true|false|undefined|null|NaN|this)($|\.|\ )/g
  };

  Helper.prototype.parseSelf = false;

  Helper.prototype.orderPriority = 0;

  function Helper(opts) {
    var attr, value, _i, _len, _ref, _ref1;
    Helper.__super__.constructor.apply(this, arguments);
    this._setAccessor('_main', opts.mainAttr);
    if (this.attributes) {
      _ref = this.attributes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attr = _ref[_i];
        if (value = (_ref1 = this.el.attributes[Neck.Tools.camelToDash(attr)]) != null ? _ref1.value : void 0) {
          this._setAccessor(attr, value);
        }
      }
    }
  }

  Helper.prototype._parseValue = function(s) {
    var resolves, texts,
      _this = this;
    s = s.trim();
    texts = [];
    resolves = [];
    s = s.replace(this.REGEXPS.TEXTS, function(t) {
      texts.push(t);
      return "###";
    });
    s = s.replace(this.REGEXPS.PROPERTIES, function(t) {
      var sub;
      if ((sub = t.substr(0, 1)) !== '@') {
        if (!(sub === '.' || t.match(_this.REGEXPS.RESERVED_KEYWORDS))) {
          resolves.push(t.match(_this.REGEXPS.FUNCTION) ? t.split('.')[0] : t);
        }
      } else {
        t = '_context.' + t.substr(1);
      }
      return t;
    });
    if (texts.length) {
      s = s.replace(this.REGEXPS.TEXTS_HASHED, function() {
        return texts.shift();
      });
    }
    return [s, _.uniq(resolves)];
  };

  Helper.prototype._setAccessor = function(key, value) {
    var controller, options, resolve, resolves, shortValueKey, strictValue, _getter, _i, _len, _ref, _setter,
      _this = this;
    strictValue = false;
    _ref = this._parseValue(value), value = _ref[0], resolves = _ref[1];
    _getter = new Function("__scope", "with (__scope) { __return = " + (value || void 0) + " } return __return");
    options = {
      enumerable: true,
      get: function() {
        var e;
        try {
          if (strictValue) {
            return value;
          }
          return _getter.call(window, _this.parent.scope);
        } catch (_error) {
          e = _error;
          return void 0;
        }
      }
    };
    if (value.match(this.REGEXPS.ONLY_PROPERTY) && !value.match(this.REGEXPS.RESERVED_KEYWORDS)) {
      shortValueKey = value.split('.')[0];
      _setter = new Function("__scope, __newVal", "with (__scope) { return " + value + " = __newVal; };");
      options.set = function(newVal) {
        var _return;
        _return = _setter.call(window, _this.parent.scope, newVal);
        if (shortValueKey !== value) {
          _this.parent.apply(shortValueKey);
        }
        return _return;
      };
    } else {
      options.set = function(newVal) {
        var _return;
        strictValue = true;
        _return = value = newVal;
        _this.apply(key);
        return _return;
      };
    }
    Object.defineProperty(this.scope, key, options);
    this.scope._resolves[key] = [];
    for (_i = 0, _len = resolves.length; _i < _len; _i++) {
      resolve = resolves[_i];
      controller = this;
      while (controller = controller.parent) {
        if (controller.scope._resolves[resolve]) {
          this.scope._resolves[key] = _.union(this.scope._resolves[key], this.parent.scope._resolves[resolve]);
          break;
        }
        if (controller.scope.hasOwnProperty(resolve.split('.')[0])) {
          this._addResolver(key, controller, resolve);
          break;
        } else if (!controller.parent) {
          this._addResolver(key, this.parent, resolve);
        }
      }
    }
    if (!this.scope._resolves[key].length) {
      return this.scope._resolves[key] = void 0;
    }
  };

  Helper.prototype._addResolver = function(key, controller, resolve) {
    var chain, obj, objName, param;
    this.scope._resolves[key].push({
      controller: controller,
      key: resolve
    });
    chain = resolve.split('.');
    param = chain.pop();
    obj = controller.scope;
    while (objName = chain.shift()) {
      if (!obj[objName]) {
        obj[objName] = {};
      }
      obj = obj[objName];
    }
    if (!obj.hasOwnProperty(param)) {
      return obj[param] || (obj[param] = void 0);
    }
  };

  return Helper;

})(Neck.Controller);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

Neck.Router = (function(_super) {
  __extends(Router, _super);

  Router.prototype.PARAM_REGEXP = /\:(\w+)/gi;

  function Router(opts) {
    Router.__super__.constructor.apply(this, arguments);
    if (!(this.app = opts != null ? opts.app : void 0)) {
      throw "Neck.Router require connection with App Controller";
    }
  }

  Router.prototype.route = function(route, settings) {
    var myCallback,
      _this = this;
    if (!settings.yields) {
      if (typeof settings === 'object') {
        settings = {
          yields: {
            main: settings
          }
        };
      } else if (typeof settings === 'string') {
        settings = {
          yields: {
            main: {
              controller: settings
            }
          }
        };
      } else {
        throw "Route structure has to be object or controller name";
      }
    }
    myCallback = function() {
      var args, options, query, yieldName, _ref, _ref1, _yield;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      query = {};
      if (typeof (query = _.last(args)) === 'object') {
        args.pop();
      }
      if (args.length && !_.isRegExp(route)) {
        route.replace(_this.PARAM_REGEXP, function(all, name) {
          var param;
          if (param = args.shift()) {
            return query[name] = param;
          }
        });
      }
      _ref = settings.yields;
      for (yieldName in _ref) {
        options = _ref[yieldName];
        if (!(_yield = (_ref1 = _this.app._yieldList) != null ? _ref1[yieldName] : void 0)) {
          throw "No '" + yieldName + "' yield defined in App";
        }
        if (options === false) {
          return _yield.clear();
        }
        _yield.append(options.controller || options, _.extend({}, options.params, query), options.refresh, options.replace);
      }
      if (settings.state) {
        return _this.app.scope._state = settings.state;
      }
    };
    return Router.__super__.route.call(this, route, myCallback);
  };

  return Router;

})(Backbone.Router);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.App = (function(_super) {
  __extends(App, _super);

  App.prototype.routes = false;

  App.prototype.history = {
    pushState: true
  };

  function App(opts) {
    var _this = this;
    App.__super__.constructor.apply(this, arguments);
    if (this.routes) {
      this.router = new Neck.Router({
        app: this,
        routes: this.routes
      });
      if (this.history) {
        this.once('render:after', function() {
          return Backbone.history.start(_this.history);
        });
      }
    }
  }

  return App;

})(Neck.Controller);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.attr = (function(_super) {
  __extends(attr, _super);

  function attr() {
    attr.__super__.constructor.apply(this, arguments);
    if (typeof this.scope._main !== 'object') {
      throw "'ui-attr' attribute has to be object";
    }
    this.watch('_main', function(main) {
      var key, returnedValue, value;
      for (key in main) {
        value = main[key];
        if (returnedValue = value) {
          this.$el.attr(key, returnedValue === true ? key : returnedValue);
        } else {
          this.$el.removeAttr(key);
        }
      }
      return void 0;
    });
  }

  return attr;

})(Neck.Helper);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.bind = (function(_super) {
  __extends(bind, _super);

  bind.prototype.attributes = ['bindProperty'];

  bind.prototype.NUMBER = /^[0-9]+((\.|\,)?[0-9]+)*$/;

  bind.prototype.events = {
    "keydown": "update",
    "change": "update",
    "search": "update"
  };

  bind.prototype.isCheckbox = false;

  function bind() {
    bind.__super__.constructor.apply(this, arguments);
    if (this.$el.is(':checkbox')) {
      this.isCheckbox = true;
    }
    this.watch('_main', function() {
      if (this.scope._main instanceof Backbone.Model) {
        if (!this.scope.bindProperty) {
          throw 'Backbone.Model property required';
        }
        if (typeof this.scope.bindProperty !== 'string') {
          throw 'Property has to be a string';
        }
      }
      if (!this._updated) {
        if (this.isCheckbox) {
          this.$el.prop('checked', this.getValue());
        } else {
          this.$el.val(this.getValue() || '');
        }
      }
      return this._updated = false;
    });
  }

  bind.prototype.calculateValue = function(s) {
    if (s.match(this.NUMBER)) {
      return Number(s.replace(',', '.'));
    } else {
      return s;
    }
  };

  bind.prototype.update = function() {
    var _this = this;
    return setTimeout(function() {
      if (!_this.scope) {
        return;
      }
      if (_this.isCheckbox) {
        return _this.setValue(_this.$el.is(':checked') ? 1 : 0);
      } else {
        return _this.setValue(_this.calculateValue(_this.$el.val()));
      }
    });
  };

  bind.prototype.getValue = function() {
    if (this.scope._main instanceof Backbone.Model) {
      return this.scope._main.get(this.scope.bindProperty);
    } else {
      return this.scope._main;
    }
  };

  bind.prototype.setValue = function(value) {
    this._updated = true;
    if (this.scope._main instanceof Backbone.Model) {
      return this.scope._main.set(this.scope.bindProperty, value);
    } else {
      return this.scope._main = value;
    }
  };

  return bind;

})(Neck.Helper);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper["class"] = (function(_super) {
  __extends(_class, _super);

  function _class() {
    _class.__super__.constructor.apply(this, arguments);
    if (typeof this.scope._main !== 'object') {
      throw "'ui-class' attribute has to be object";
    }
    this.watch('_main', function(main) {
      var key, value;
      for (key in main) {
        value = main[key];
        this.$el.toggleClass(key, value ? true : false);
      }
      return void 0;
    });
  }

  return _class;

})(Neck.Helper);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

Neck.Helper.collectionItem = (function(_super) {
  __extends(collectionItem, _super);

  collectionItem.prototype.divWrapper = false;

  function collectionItem(opts) {
    var _this = this;
    collectionItem.__super__.constructor.apply(this, arguments);
    this.model = opts.model;
    Object.defineProperty(this.scope, opts.itemName, {
      enumerable: true,
      writable: true,
      configurable: true,
      value: opts.model
    });
    this.scope._index = opts.index;
    if (opts.externalTemplate) {
      this.listenTo(this.scope[opts.itemName], 'change', function() {
        return _this.$el.replaceWith(_this.render().$el);
      });
    }
  }

  return collectionItem;

})(Neck.Controller);

Neck.Helper.collection = (function(_super) {
  __extends(collection, _super);

  collection.prototype.attributes = ['collectionItem', 'collectionSort', 'collectionFilter', 'collectionView', 'collectionEmpty', 'collectionController'];

  collection.prototype.template = true;

  collection.prototype.itemController = Neck.Helper.collectionItem;

  function collection() {
    this.resetItems = __bind(this.resetItems, this);
    this.sortItems = __bind(this.sortItems, this);
    this.removeItem = __bind(this.removeItem, this);
    this.addItem = __bind(this.addItem, this);
    var controller, _base;
    collection.__super__.constructor.apply(this, arguments);
    this.itemTemplate = this.template;
    if (this.scope.collectionView) {
      this.itemTemplate = this.scope.collectionView;
    }
    this.template = this.scope.collectionEmpty;
    if (controller = this.scope.collectionController) {
      if (typeof controller === 'string') {
        this.itemController = this.injector.load(controller, {
          type: 'controller'
        });
      } else {
        this.itemController = controller;
      }
    }
    (_base = this.scope).collectionItem || (_base.collectionItem = 'item');
    this.items = [];
    this.watch('collectionSort', function(sort) {
      if (sort && this.collection) {
        this.collection.comparator = sort;
        return this.collection.sort();
      }
    });
    this.watch('collectionFilter', function(filter) {
      var item, _i, _j, _len, _len1, _ref, _ref1;
      if (filter || filter === "") {
        if (typeof filter === 'string') {
          filter = new RegExp(filter, "gi");
          _ref = this.items;
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            item = _ref[_i];
            if ((item.model + "").match(filter)) {
              item.$el.removeClass('ui-hide');
            } else {
              item.$el.addClass('ui-hide');
            }
          }
          return void 0;
        } else if (typeof filter === 'function') {
          _ref1 = this.items;
          for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
            item = _ref1[_j];
            if (filter(item.model)) {
              item.$el.removeClass('ui-hide');
            } else {
              item.$el.addClass('ui-hide');
            }
          }
          return void 0;
        }
      }
    });
    this.watch('_main', function(collection) {
      if (collection === this.collection || !(collection instanceof Backbone.Collection)) {
        return;
      }
      if (this.collection) {
        this.stopListening(this.collection);
      }
      if (this.collection = collection) {
        this.apply('collectionSort');
        this.apply('collectionFilter');
        this.listenTo(this.collection, "add", this.addItem);
        this.listenTo(this.collection, "remove", this.removeItem);
        this.listenTo(this.collection, "sort", this.sortItems);
        this.listenTo(this.collection, "reset", this.resetItems);
      }
      return this.resetItems();
    });
  }

  collection.prototype.addItem = function(model) {
    var item;
    if (!this.items.length) {
      this.$el.empty();
    }
    this.items.push(item = new this.itemController({
      template: this.itemTemplate,
      externalTemplate: this.scope.collectionView,
      parent: this.parent,
      model: model,
      itemName: this.scope.collectionItem,
      index: this.items.length
    }));
    return this.$el.append(item.render().$el);
  };

  collection.prototype.removeItem = function(model) {
    var item, _ref;
    item = _.findWhere(this.items, {
      model: model
    });
    this.items.splice(this.items.indexOf(item), 1);
    item.remove();
    if (!((_ref = this.collection) != null ? _ref.length : void 0)) {
      return this.renderEmpty();
    }
  };

  collection.prototype.sortItems = function() {
    var model, _i, _len, _ref;
    _ref = this.collection.models;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      model = _ref[_i];
      _.findWhere(this.items, {
        model: model
      }).$el.appendTo(this.$el);
    }
    return void 0;
  };

  collection.prototype.resetItems = function() {
    var item, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    _ref = this.items;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      item.remove();
    }
    this.items = [];
    this.$el.empty();
    if ((_ref1 = this.collection) != null ? _ref1.length : void 0) {
      _ref2 = this.collection.models;
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        item = _ref2[_j];
        this.addItem(item);
      }
      return void 0;
    } else {
      return this.renderEmpty();
    }
  };

  collection.prototype.renderEmpty = function() {
    if (this.template) {
      return this.render();
    }
  };

  return collection;

})(Neck.Helper);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.element = (function(_super) {
  __extends(element, _super);

  function element() {
    var _ref;
    element.__super__.constructor.apply(this, arguments);
    if (typeof this.scope._main !== 'string') {
      throw "'ui-element' attribute has to be string";
    }
    if ((_ref = this.parent) != null) {
      _ref.scope[this.scope._main] = this.$el;
    }
  }

  return element;

})(Neck.Helper);


})();

;(function() {
/* LIST OF EVENTS TO TRIGGER*/

var ER, Event, EventHelper, EventList, ev, helper, _i, _len, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

EventList = ["click", "dblclick", "mouseenter", "mouseleave", "mouseout", "mouseover", "mousedown", "mouseup", "drag", "dragstart", "dragenter", "dragleave", "dragover", "dragend", "drop", "load", "focus", "focusin", "focusout", "select", "blur", "submit", "scroll", "touchstart", "touchend", "touchmove", "touchenter", "touchleave", "touchcancel", "keyup", "keydown", "keypress"];

EventHelper = (function(_super) {
  __extends(EventHelper, _super);

  function EventHelper(opts) {
    EventHelper.__super__.constructor.apply(this, arguments);
    if (typeof this.scope._main === 'function') {
      this.scope._main.call(this.scope._context, opts.e);
    }
    this.apply('_main');
    this.off();
    this.stopListening();
  }

  EventHelper.prototype._resolveKey = function(scope, keyChain) {
    var key, keys, property;
    keys = keyChain.split('.');
    property = keys.pop();
    while (key = keys.shift()) {
      scope = scope[key];
    }
    return [scope, property];
  };

  EventHelper.prototype.apply = function(key) {
    var index, newResolves, obj, resolve, _i, _len, _ref, _ref1, _ref2, _ref3;
    if ((_ref = this.scope) != null ? _ref._resolves[key] : void 0) {
      newResolves = [];
      _ref1 = this.scope._resolves[key];
      for (index = _i = 0, _len = _ref1.length; _i < _len; index = ++_i) {
        resolve = _ref1[index];
        _ref2 = this._resolveKey(resolve.controller.scope, resolve.key), obj = _ref2[0], key = _ref2[1];
        if (!((_ref3 = Object.getOwnPropertyDescriptor(obj, key)) != null ? _ref3.get : void 0)) {
          newResolves.push(resolve);
        }
      }
      if (newResolves.length) {
        this.scope._resolves[key] = newResolves;
        return EventHelper.__super__.apply.apply(this, arguments);
      }
    }
  };

  return EventHelper;

})(Neck.Helper);

Event = (function() {
  Event.prototype.template = false;

  function Event(options) {
    var _this = this;
    if (options.el[0].tagName === 'A') {
      if (!options.el.attr('href')) {
        options.el.attr('href', '#');
      }
    }
    options.el.on(this.eventType, function(e) {
      e.preventDefault();
      options.e = e;
      return new EventHelper(options);
    });
  }

  return Event;

})();

for (_i = 0, _len = EventList.length; _i < _len; _i++) {
  ev = EventList[_i];
  helper = ER = (function(_super) {
    __extends(ER, _super);

    function ER() {
      _ref = ER.__super__.constructor.apply(this, arguments);
      return _ref;
    }

    return ER;

  })(Event);
  helper.prototype.eventType = ev;
  Neck.Helper[Neck.Tools.dashToCamel("event-" + ev)] = helper;
}


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.hide = (function(_super) {
  __extends(hide, _super);

  function hide() {
    hide.__super__.constructor.apply(this, arguments);
    this.watch('_main', function(value) {
      return this.$el.toggleClass('ui-hide', value ? true : false);
    });
  }

  return hide;

})(Neck.Helper);


})();

;(function() {
var HrefHelper,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

HrefHelper = (function(_super) {
  __extends(HrefHelper, _super);

  function HrefHelper(opts) {
    HrefHelper.__super__.constructor.apply(this, arguments);
    opts.e.preventDefault();
    Neck.Router.prototype.navigate(this.scope._main, {
      trigger: true
    });
  }

  return HrefHelper;

})(Neck.Helper);

Neck.Helper.href = (function() {
  href.prototype.template = false;

  function href(opts) {
    opts.el.attr('href', '#');
    opts.el.on('click', function(e) {
      return new HrefHelper(_.extend(opts, {
        e: e
      }));
    });
  }

  return href;

})();


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.init = (function(_super) {
  __extends(init, _super);

  function init() {
    init.__super__.constructor.apply(this, arguments);
    if (typeof this.scope._main === 'function') {
      this.scope._main.call(this.scope._context);
    }
  }

  return init;

})(Neck.Helper);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.listItem = (function(_super) {
  __extends(listItem, _super);

  listItem.prototype.divWrapper = false;

  function listItem(opts) {
    listItem.__super__.constructor.apply(this, arguments);
    this.item = opts.item;
    Object.defineProperty(this.scope, opts.itemName, {
      enumerable: true,
      writable: true,
      configurable: true,
      value: opts.item
    });
    this.scope._index = opts.index;
  }

  return listItem;

})(Neck.Controller);

Neck.Helper.list = (function(_super) {
  __extends(list, _super);

  list.prototype.attributes = ['listItem', 'listSort', 'listFilter', 'listView', 'listEmpty', 'listController'];

  list.prototype.template = true;

  list.prototype.itemController = Neck.Helper.listItem;

  function list() {
    var controller;
    list.__super__.constructor.apply(this, arguments);
    this.itemTemplate = this.template;
    if (this.scope.listView) {
      this.itemTemplate = this.scope.listView;
    }
    this.template = this.scope.listEmpty;
    if (controller = this.scope.listController) {
      if (typeof controller === 'string') {
        this.itemController = this.injector.load(controller, {
          type: 'controller'
        });
      } else {
        this.itemController = controller;
      }
    }
    this.itemName || (this.itemName = 'item');
    this.items = [];
    this.watch('_main', function(list) {
      this.list = list;
      if (!(this.list instanceof Array)) {
        return this.resetItems();
      } else {
        this.resetItems();
        if (this.scope.listSort) {
          this.apply('listSort');
        }
        if (this.scope.listFilter) {
          return this.apply('listFilter');
        }
      }
    });
    this.watch('listSort', function(sort) {
      var item, _i, _len, _ref;
      if (sort && this.list) {
        this.list = _.sortBy(this.list, function(i) {
          return sort(i);
        });
        _ref = this.list;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          item = _ref[_i];
          _.findWhere(this.items, {
            item: item
          }).$el.appendTo(this.$el);
        }
        return void 0;
      }
    });
    this.watch('listFilter', function(filter) {
      var i, _i, _len, _ref;
      if (filter || filter === "") {
        filter = new RegExp(filter, "gi");
        _ref = this.items;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          i = _ref[_i];
          if ((i.item + "").match(filter)) {
            i.$el.removeClass('ui-hide');
          } else {
            i.$el.addClass('ui-hide');
          }
        }
        return void 0;
      }
    });
  }

  list.prototype.resetItems = function() {
    var item, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    _ref = this.items;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      item.remove();
    }
    this.items = [];
    this.$el.empty();
    if ((_ref1 = this.list) != null ? _ref1.length : void 0) {
      _ref2 = this.list;
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        item = _ref2[_j];
        this.add(item);
      }
      return void 0;
    } else if (this.scope.listEmpty && this.template) {
      return this.render();
    }
  };

  list.prototype.add = function(item) {
    this.items.push(item = new this.itemController({
      template: this.itemTemplate,
      parent: this,
      item: item,
      itemName: this.itemName,
      index: this.items.length
    }));
    return this.$el.append(item.render().$el);
  };

  return list;

})(Neck.Helper);


})();

;(function() {
$(function() {
  return $('[ui-neck]').each(function() {
    var Controller, controller, el, injector, name;
    el = $(this);
    name = eval(el.attr('ui-neck'));
    injector = Neck.DI[el.attr('neck-injector') ? eval(el.attr('neck-injector')) : 'globals'];
    Controller = injector.load(name, {
      type: 'controller'
    });
    el.removeAttr('ui-neck');
    controller = new Controller({
      el: el,
      template: name
    });
    controller.injector = injector;
    return controller.render();
  });
});


})();

;(function() {
var RouteHelper,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

RouteHelper = (function(_super) {
  __extends(RouteHelper, _super);

  RouteHelper.prototype.attributes = ['routeYield', 'routeReplace', 'routeParams', 'routeRefresh'];

  function RouteHelper(opts) {
    var container, target;
    RouteHelper.__super__.constructor.apply(this, arguments);
    opts.e.preventDefault();
    container = this.scope.routeYield || 'main';
    if (!(target = this.scope._context._yieldList[container])) {
      throw "No yield '" + container + "' for route in yields chain";
    }
    target.append(this.scope._main, this.scope.routeParams, this.scope.routeRefresh, this.scope.routeReplace);
  }

  return RouteHelper;

})(Neck.Helper);

Neck.Helper.route = (function() {
  route.prototype.template = false;

  function route(opts) {
    opts.el.on('click', function(e) {
      return new RouteHelper(_.extend(opts, {
        e: e
      }));
    });
  }

  return route;

})();


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.show = (function(_super) {
  __extends(show, _super);

  function show() {
    show.__super__.constructor.apply(this, arguments);
    this.$el.addClass('ui-hide');
    this.watch('_main', function(value) {
      return this.$el.toggleClass('ui-hide', !value ? true : false);
    });
  }

  return show;

})(Neck.Helper);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.template = (function(_super) {
  __extends(template, _super);

  template.prototype.template = true;

  function template() {
    var _this = this;
    template.__super__.constructor.apply(this, arguments);
    this.scope._main = this.template;
    this.$el.addClass('ui-hide');
    setTimeout(function() {
      return _this.remove();
    });
  }

  return template;

})(Neck.Helper);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.value = (function(_super) {
  __extends(value, _super);

  function value() {
    value.__super__.constructor.apply(this, arguments);
    this.watch('_main', function(value) {
      return this.$el.text(value === void 0 ? "" : value);
    });
  }

  return value;

})(Neck.Helper);


})();

;(function() {
var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper["yield"] = (function(_super) {
  __extends(_yield, _super);

  _yield.prototype.attributes = ['yieldView', 'yieldParams', 'yieldReplace', 'yieldInherit'];

  _yield.prototype.template = true;

  _yield.prototype.replace = false;

  function _yield() {
    var _base,
      _this = this;
    _yield.__super__.constructor.apply(this, arguments);
    this.name = this.scope._main || "main";
    this.context = this.scope._context;
    this.list = (_base = this.context)._yieldList || (_base._yieldList = {});
    if (this.list[this.name]) {
      throw "There is already yield with '" + this.name + "' name in App";
    } else {
      this.list[this.name] = this;
    }
    this.listenTo(this.context, 'render:clear remove:after', function() {
      return delete _this.list[_this.name];
    });
    this.replace || (this.replace = this.scope.yieldReplace);
    if (this.scope.yieldView) {
      this.append(this.scope.yieldView, this.scope.yieldParams);
    }
  }

  _yield.prototype._createController = function(controllerPath, params, parent) {
    var Controller, controller;
    Controller = this.injector.load(controllerPath, {
      type: 'controller'
    });
    controller = new Controller({
      template: "" + controllerPath,
      params: params,
      parent: this.scope.yieldInherit ? this.context : void 0
    });
    controller.injector = this.context.injector;
    if (this.scope.yieldInherit) {
      controller.scope._context = controller;
    }
    controller._yieldList = Object.create(this.list);
    controller._yieldPath = controllerPath;
    parent._yieldChild = controller;
    parent.listenTo(controller, "remove:after", function() {
      return this._yieldChild = void 0;
    });
    controller.listenTo(parent, "remove:after", function() {
      return controller.remove();
    });
    this.$el.append(controller.render().$el);
    return controller;
  };

  _yield.prototype.append = function(controllerPath, params, refresh, replace) {
    var child, parent, _ref, _ref1;
    if (refresh == null) {
      refresh = false;
    }
    if (replace == null) {
      replace = this.replace;
    }
    if (replace && this._yieldChild) {
      if (controllerPath === this._yieldChild._yieldPath) {
        if (this._yieldChild._events["render:refresh"] || !refresh) {
          if ((_ref = this._yieldChild._yieldChild) != null) {
            _ref.remove();
          }
        } else {
          this._yieldChild.remove();
          this._yieldChild = void 0;
        }
      } else {
        this._yieldChild.remove();
        this._yieldChild = void 0;
      }
    }
    parent = this;
    child = void 0;
    while (parent._yieldChild) {
      child = parent._yieldChild;
      if (child._yieldPath === controllerPath) {
        if (refresh && !child._events["render:refresh"]) {
          child.remove();
          break;
        } else {
          child.trigger("render:refresh");
          if ((_ref1 = child._yieldChild) != null) {
            _ref1.remove();
          }
          child._yieldChild = void 0;
          return child;
        }
      }
      parent = parent._yieldChild;
    }
    return this._createController(controllerPath, params, parent);
  };

  _yield.prototype.clear = function() {
    if (this._yieldChild) {
      this._yieldChild.remove();
      return this._yieldChild = void 0;
    }
  };

  return _yield;

})(Neck.Helper);


})();

;// Closing wrapper
return Neck; }));
;
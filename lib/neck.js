(function() {var Neck,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  __slice = [].slice;

window.Neck = Neck = {};

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

Neck.DI = {
  controllerPrefix: 'controllers',
  helperPrefix: 'helpers',
  templatePrefix: 'templates',
  _routePath: /^([a-zA-Z$_\.]+\/?)+$/i,
  load: function(route, options) {
    if (route.match(this._routePath)) {
      try {
        return require((options.type ? this[options.type + 'Prefix'] + "/" : '') + route);
      } catch (_error) {
        if (window[route]) {
          return window[route];
        } else if (options.type !== 'template') {
          throw "No defined '" + route + "' object for Neck dependency injection";
        }
      }
    }
    return route;
  }
};

Neck.Controller = (function(_super) {
  __extends(Controller, _super);

  Controller.prototype.REGEXPS = {
    TEXTS: /\'[^\']+\'/g,
    RESERVED_KEYWORDS: new RegExp("^(do|if|in|for|let|new|try|var|case|else|enum|eval|false|null|this|true|\nvoid|with|break|catch|class|const|super|throw|while|yield|delete|export|import|public|\nreturn|static|switch|typeof|default|extends|finally|package|private|continue|debugger|\nfunction|arguments|interface|protected|implements|instanceof|undefined|window)($|\.)"),
    SCOPE_PROPERTIES: /([a-zA-Z$_\@][^\ \[\]\:\(\)\{\}]*)/g,
    TWICE_SCOPE: /(scope\.[^\ ]*\.)scope\./,
    EXPRESSION: /[-+=\(\)\{\}\:]+/,
    METHOD: /[a-zA-Z$_][^\ \(\)\{\}\:]*\(/,
    OBJECT: /^\{.+\}$/g,
    ONLY_PROPERTY: /^[a-zA-Z$_][^\ \(\)\{\}\:]*$/g,
    SLASHES: /\//g
  };

  Controller.prototype.divWrapper = true;

  Controller.prototype.template = false;

  function Controller(opts) {
    this.clear = __bind(this.clear, this);
    this.remove = __bind(this.remove, this);
    var scope;
    Controller.__super__.constructor.apply(this, arguments);
    scope = (this.parent = opts != null ? opts.parent : void 0) ? Object.create(this.parent.scope) : {
      _context: this
    };
    this.scope = _.extend(scope, this.scope, {
      _resolves: {}
    });
    if (this.parent) {
      this.listenTo(this.parent, 'remove', this.remove);
      this.listenTo(this.parent, 'clear', this.clear);
    }
    if (opts.template) {
      this.template = opts.template;
    }
    if (this.template === true) {
      this.template = this.$el.html();
      this.$el.empty();
    }
    this.params = opts.params || {};
  }

  Controller.prototype.remove = function() {
    this.trigger('remove');
    this.parent = void 0;
    this.scope = void 0;
    return Controller.__super__.remove.apply(this, arguments);
  };

  Controller.prototype.clear = function() {
    this.trigger('clear');
    this.off();
    return this.stopListening();
  };

  Controller.prototype.render = function() {
    var el, template, _i, _len, _ref;
    this.trigger('clear');
    if (this.template) {
      if (typeof (template = Neck.DI.load(this.template, {
        type: 'template'
      })) === 'function') {
        template = template(this.scope);
      }
      if (this.divWrapper) {
        this.$el.html(template);
      } else {
        this.setElement($(template));
      }
    }
    _ref = this.$el;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      el = _ref[_i];
      this._parseNode(el);
    }
    return this;
  };

  Controller.prototype._parseNode = function(node) {
    var attribute, child, el, helper, name, stop, _i, _j, _len, _len1, _ref, _ref1, _ref2;
    if (node != null ? node.attributes : void 0) {
      el = null;
      _ref = node.attributes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        attribute = _ref[_i];
        if (((_ref1 = attribute.nodeName) != null ? _ref1.substr(0, 3) : void 0) === "ui-") {
          el || (el = $(node));
          name = Neck.Tools.dashToCamel(attribute.nodeName.substr(3));
          helper = new (Neck.Helper[name] || Neck.DI.load(name, {
            type: 'helper'
          }))({
            el: el,
            parent: this,
            mainAttr: attribute.value
          });
          if (helper.template !== false) {
            stop = true;
          }
        }
      }
    }
    if (!(stop || !node)) {
      _ref2 = node.childNodes;
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        child = _ref2[_j];
        this._parseNode(child);
      }
    }
    return void 0;
  };

  Controller.prototype._parseValue = function(s) {
    var resolves, texts,
      _this = this;
    s = s.trim();
    texts = [];
    resolves = [];
    s = s.replace(this.REGEXPS.TEXTS, function(t) {
      texts.push(t);
      return "###";
    });
    s = s.replace(this.REGEXPS.SCOPE_PROPERTIES, function(t) {
      if (!t.match(_this.REGEXPS.RESERVED_KEYWORDS)) {
        if (t.substr(0, 1) !== '@') {
          resolves.push(t.split('.')[0]);
        } else {
          t = '_context.' + t.substr(1);
        }
        return "scope." + t;
      } else {
        return t;
      }
    });
    while (s.match(this.REGEXPS.TWICE_SCOPE)) {
      s = s.replace(this.REGEXPS.TWICE_SCOPE, "$1");
    }
    if (texts.length) {
      s = s.replace(/###/g, function() {
        return texts.shift();
      });
    }
    if (s.match(this.REGEXPS.OBJECT)) {
      s = "(" + s + ")";
    }
    return [s, _.uniq(resolves)];
  };

  Controller.prototype._setAccessor = function(key, value, controller) {
    var options, resolve, resolves, scope, _i, _len, _ref,
      _this = this;
    if (controller == null) {
      controller = this.parent;
    }
    scope = controller.scope;
    _ref = this._parseValue(value), value = _ref[0], resolves = _ref[1];
    options = {
      enumerable: true,
      get: function() {
        var e;
        try {
          return eval(value);
        } catch (_error) {
          e = _error;
          return void 0;
        }
      }
    };
    if (value.match(this.REGEXPS.EXPRESSION)) {
      options.get = function() {
        var e;
        try {
          eval(value);
          return _this.apply(key);
        } catch (_error) {
          e = _error;
          return void 0;
        }
      };
    }
    if (value.match(this.REGEXPS.ONLY_PROPERTY)) {
      options.set = function(newVal) {
        var e, m, model, obj, property, _i, _len, _ref1;
        model = value.split('.');
        property = model.pop();
        obj = scope;
        _ref1 = model.slice(1);
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          m = _ref1[_i];
          if (!obj[m]) {
            obj = obj[m] = {};
          }
        }
        try {
          (eval(model.join('.')))[property] = newVal;
          if (model.length > 1) {
            return _this.apply(key);
          }
        } catch (_error) {
          e = _error;
          return void 0;
        }
      };
    }
    Object.defineProperty(this.scope, key, options);
    if (controller !== this) {
      this.scope._resolves[key] = [];
      for (_i = 0, _len = resolves.length; _i < _len; _i++) {
        resolve = resolves[_i];
        if (controller.scope._resolves[resolve]) {
          this.scope._resolves[key] = _.union(this.scope._resolves[key], controller.scope._resolves[resolve]);
        } else {
          this.scope._resolves[key].push({
            controller: controller,
            key: resolve
          });
        }
      }
      if (!this.scope._resolves[key].length) {
        return this.scope._resolves[key] = void 0;
      }
    }
  };

  Controller.prototype._watch = function(key, callback, context) {
    var controller, resolve, val, _i, _len, _ref, _ref1,
      _this = this;
    if (context == null) {
      context = this;
    }
    if (this.scope.hasOwnProperty(key) || !this.parent) {
      if ((_ref = Object.getOwnPropertyDescriptor(this.scope, key)) != null ? _ref.get : void 0) {
        if (this.scope._resolves[key]) {
          _ref1 = this.scope._resolves[key];
          for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
            resolve = _ref1[_i];
            resolve.controller._watch(resolve.key, callback, context);
          }
          return void 0;
        } else {
          return context.listenTo(this, "refresh:" + key, callback);
        }
      } else {
        val = this.scope[key];
        if (val instanceof Backbone.Model) {
          this.listenTo(val, "sync", function() {
            return _this.apply(key);
          });
        }
        Object.defineProperty(this.scope, key, {
          enumerable: true,
          get: function() {
            return val;
          },
          set: function(newVal) {
            if (val instanceof Backbone.Model) {
              _this.stopListening(val);
            }
            if (newVal instanceof Backbone.Model) {
              _this.listenTo(newVal, "sync", function() {
                return _this.apply(key);
              });
            }
            val = newVal;
            return _this.apply(key);
          }
        });
        return context.listenTo(this, "refresh:" + key, callback);
      }
    } else {
      controller = this;
      while (controller = controller.parent) {
        if (controller.scope.hasOwnProperty(key)) {
          controller._watch(key, callback, context);
          break;
        }
      }
      return void 0;
    }
  };

  Controller.prototype.watch = function() {
    var call, callback, key, keys, _i, _j, _len,
      _this = this;
    keys = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), callback = arguments[_i++];
    call = function() {
      return callback.apply(_this, _.map(keys, function(k) {
        return _this.scope[k];
      }));
    };
    for (_j = 0, _len = keys.length; _j < _len; _j++) {
      key = keys[_j];
      this._watch(key.split('.')[0], call);
    }
    return call();
  };

  Controller.prototype.apply = function(key) {
    var resolve, _i, _len, _ref;
    if (this.scope._resolves[key]) {
      _ref = this.scope._resolves[key];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        resolve = _ref[_i];
        resolve.controller.trigger("refresh:" + resolve.key);
      }
      return void 0;
    } else {
      return this.trigger("refresh:" + key);
    }
  };

  return Controller;

})(Backbone.View);

Neck.Helper = (function(_super) {
  __extends(Helper, _super);

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

  return Helper;

})(Neck.Controller);

})();

;(function() {var __hasProp = {}.hasOwnProperty,
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

;(function() {var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.bind = (function(_super) {
  __extends(bind, _super);

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
    this.watch('_main', function(value) {
      if (!this._updated) {
        if (this.isCheckbox) {
          this.$el.prop('checked', value);
        } else {
          this.$el.val(value || '');
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
      _this._updated = true;
      if (_this.isCheckbox) {
        return _this.scope._main = _this.$el.is(':checked') ? 1 : 0;
      } else {
        return _this.scope._main = _this.calculateValue(_this.$el.val());
      }
    });
  };

  return bind;

})(Neck.Helper);

})();

;(function() {var __hasProp = {}.hasOwnProperty,
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
        if (value) {
          this.$el.addClass(key);
        } else {
          this.$el.removeClass(key);
        }
      }
      return void 0;
    });
  }

  return _class;

})(Neck.Helper);

})();

;(function() {var Item,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.collection = (function(_super) {
  __extends(collection, _super);

  collection.prototype.attributes = ['collectionItem', 'collectionSort', 'collectionFilter', 'collectionView'];

  collection.prototype.template = true;

  function collection() {
    this.resetItems = __bind(this.resetItems, this);
    this.sortItems = __bind(this.sortItems, this);
    this.removeItem = __bind(this.removeItem, this);
    this.addItem = __bind(this.addItem, this);
    var _base;
    collection.__super__.constructor.apply(this, arguments);
    if (!(this.scope._main instanceof Backbone.Collection)) {
      return new Error("Given object has to be instance of Backbone.Collection");
    }
    if (this.scope.collectionView) {
      this.template = this.scope.collectionView;
    }
    (_base = this.scope).collectionItem || (_base.collectionItem = 'item');
    this.items = [];
    this.watch('_main', function(collection) {
      if (collection !== this.collection) {
        if (this.collection) {
          this.stopListening(this.collection);
        }
        this.collection = collection;
        this.listenTo(this.collection, "add", this.addItem);
        this.listenTo(this.collection, "remove", this.removeItem);
        this.listenTo(this.collection, "sort", this.sortItems);
        this.listenTo(this.collection, "reset", this.resetItems);
        return this.resetItems();
      }
    });
    this.watch('collectionSort', function(sort) {
      if (sort) {
        this.collection.comparator = sort;
        return this.collection.sort();
      }
    });
    this.watch('collectionFilter', function(filter) {
      var item, _i, _len, _ref;
      if (filter || filter === "") {
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
      }
    });
  }

  collection.prototype.addItem = function(model) {
    var item;
    this.items.push(item = new Item({
      template: this.template,
      parent: this.parent,
      model: model,
      itemName: this.scope.collectionItem,
      index: this.items.length
    }));
    return this.$el.append(item.render().$el);
  };

  collection.prototype.removeItem = function(model) {
    return _.findWhere(this.items, {
      model: model
    }).remove();
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
    var item, _i, _j, _len, _len1, _ref, _ref1;
    _ref = this.items;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      item = _ref[_i];
      item.remove();
    }
    this.items = [];
    _ref1 = this.collection.models;
    for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
      item = _ref1[_j];
      this.addItem(item);
    }
    return void 0;
  };

  return collection;

})(Neck.Helper);

Item = (function(_super) {
  __extends(Item, _super);

  Item.prototype.divWrapper = false;

  function Item(opts) {
    var _this = this;
    Item.__super__.constructor.apply(this, arguments);
    Object.defineProperty(this.scope, opts.itemName, {
      enumerable: true,
      writable: true,
      configurable: true,
      value: opts.model
    });
    this.scope._index = opts.index;
    if (!this.templateBody) {
      this.listenTo(this.scope[opts.itemName], 'change', function() {
        return _this.$el.replaceWith(_this.render().$el);
      });
    }
  }

  return Item;

})(Neck.Controller);

})();

;(function() {var __hasProp = {}.hasOwnProperty,
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

;(function() {/* LIST OF EVENTS TO TRIGGER*/

var ER, Event, EventHelper, EventList, ev, helper, _i, _len, _ref,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

EventList = ["click", "dblclick", "mouseenter", "mouseleave", "mouseout", "mouseover", "mousedown", "mouseup", "drag", "dragstart", "dragenter", "dragleave", "dragover", "dragend", "drop", "load", "focus", "focusin", "focusout", "select", "blur", "submit", "scroll", "touchstart", "touchend", "touchmove", "touchenter", "touchleave", "touchcancel", "keyup", "keydown", "keypress"];

EventHelper = (function(_super) {
  __extends(EventHelper, _super);

  function EventHelper(opts) {
    var _this = this;
    EventHelper.__super__.constructor.apply(this, arguments);
    setTimeout(function() {
      if (typeof _this.scope._main === 'function') {
        _this.scope._main.call(_this.scope._context, opts.e);
      }
      _this.off();
      return _this.stopListening();
    });
  }

  return EventHelper;

})(Neck.Helper);

Event = (function() {
  function Event(options) {
    var _this = this;
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

;(function() {var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.hide = (function(_super) {
  __extends(hide, _super);

  function hide() {
    hide.__super__.constructor.apply(this, arguments);
    this.watch('_main', function(value) {
      if (value) {
        return this.$el.addClass('ui-hide');
      } else {
        return this.$el.removeClass('ui-hide');
      }
    });
  }

  return hide;

})(Neck.Helper);

})();

;(function() {var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.init = (function(_super) {
  __extends(init, _super);

  function init() {
    init.__super__.constructor.apply(this, arguments);
    this.watch('_main', function(main) {
      if (typeof this.scope._main === 'function') {
        return this.scope._main.call(this.scope._context);
      }
    });
  }

  return init;

})(Neck.Helper);

})();

;(function() {var Item,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.list = (function(_super) {
  __extends(list, _super);

  list.prototype.attributes = ['listItem', 'listSort', 'listFilter', 'listView'];

  list.prototype.template = true;

  function list() {
    list.__super__.constructor.apply(this, arguments);
    if (!(this.scope._main instanceof Array)) {
      return new Error("Given object has to be instance of Array");
    }
    if (this.scope.listView) {
      this.template = this.scope.listView;
    }
    this.itemName || (this.itemName = 'item');
    this.items = [];
    this.watch('_main', function(list) {
      var item, _i, _len, _ref;
      this.list = list;
      this.trigger('remove');
      _ref = this.list;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        item = _ref[_i];
        this.add(item);
      }
      return void 0;
    });
    this.watch('listSort', function(sort) {
      var item, _i, _len, _ref;
      if (sort) {
        this.list = _.sortBy(this.list, function(i) {
          return sort(i.item);
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

  list.prototype.add = function(item) {
    this.items.push(item = new Item({
      template: this.template,
      parent: this,
      item: item,
      itemName: this.itemName,
      index: this.items.length
    }));
    return this.$el.append(item.render().$el);
  };

  return list;

})(Neck.Helper);

Item = (function(_super) {
  __extends(Item, _super);

  Item.prototype.divWrapper = false;

  function Item(opts) {
    Item.__super__.constructor.apply(this, arguments);
    Object.defineProperty(this.scope, opts.itemName, {
      enumerable: true,
      writable: true,
      configurable: true,
      value: opts.item
    });
    this.scope._index = opts.index;
  }

  return Item;

})(Neck.Controller);

})();

;(function() {$(function() {
  return $('[ui-neck]').each(function() {
    var Controller, el, name;
    el = $(this);
    name = eval(el.attr('ui-neck'));
    Controller = Neck.DI.load(name, {
      type: 'controller'
    });
    el.removeAttr('ui-neck');
    return (new Controller({
      el: el
    })).render();
  });
});

})();

;(function() {var RouteHelper,
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
      throw new Error("No yield '" + container + "' for route in yields chain");
    }
    target.append(this.scope._main, this.scope.routeParams, this.scope.routeRefresh, this.scope.routeReplace);
  }

  return RouteHelper;

})(Neck.Helper);

Neck.Helper.route = (function() {
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

;(function() {var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.show = (function(_super) {
  __extends(show, _super);

  function show() {
    show.__super__.constructor.apply(this, arguments);
    this.$el.addClass('ui-hide');
    this.watch('_main', function(value) {
      if (value) {
        return this.$el.removeClass('ui-hide');
      } else {
        return this.$el.addClass('ui-hide');
      }
    });
  }

  return show;

})(Neck.Helper);

})();

;(function() {var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper.value = (function(_super) {
  __extends(value, _super);

  function value() {
    value.__super__.constructor.apply(this, arguments);
    this.watch('_main', function(value) {
      return this.$el.text(value);
    });
  }

  return value;

})(Neck.Helper);

})();

;(function() {var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Neck.Helper["yield"] = (function(_super) {
  __extends(_yield, _super);

  _yield.prototype.attributes = ['yieldView'];

  _yield.prototype.template = true;

  function _yield() {
    var _base,
      _this = this;
    _yield.__super__.constructor.apply(this, arguments);
    this.name = this.scope._main || "main";
    this.context = this.scope._context;
    this.list = (_base = this.context)._yieldList || (_base._yieldList = {});
    if (this.list[this.name]) {
      throw new Error("There is already yield with '" + this.name + "' name in App");
    } else {
      this.list[this.name] = this;
    }
    this.listenTo(this.context, 'clear remove', function() {
      return delete _this.list[_this.name];
    });
    if (this.scope.yieldView) {
      this.append(this.scope.yieldView);
    }
  }

  _yield.prototype._createController = function(controllerPath, params, parent) {
    var Controller, controller;
    Controller = Neck.DI.load(controllerPath, {
      type: 'controller'
    });
    controller = new Controller({
      template: "" + controllerPath,
      params: params
    });
    controller._yieldList = Object.create(this.list);
    controller._yieldPath = controllerPath;
    parent._yieldChild = controller;
    parent.listenTo(controller, "remove", function() {
      return this._yieldChild = void 0;
    });
    controller.listenTo(parent, "remove", function() {
      return controller.remove();
    });
    this.$el.append(controller.render().$el);
    return controller;
  };

  _yield.prototype.append = function(controllerPath, params, refresh, replace) {
    var child, parent, _ref, _ref1, _ref2;
    if (refresh == null) {
      refresh = false;
    }
    if (replace == null) {
      replace = false;
    }
    if (replace && this._yieldChild) {
      if (controllerPath === this._yieldChild._yieldPath && !refresh) {
        if ((_ref = this._yieldChild._yieldChild) != null) {
          _ref.remove();
        }
      } else {
        if ((_ref1 = this._yieldChild) != null) {
          _ref1.remove();
        }
        this._yieldChild = void 0;
      }
    }
    parent = this;
    child = void 0;
    while (parent._yieldChild) {
      child = parent._yieldChild;
      if (child._yieldPath === controllerPath) {
        if (refresh) {
          child.remove();
          break;
        } else {
          if ((_ref2 = child._yieldChild) != null) {
            _ref2.remove();
          }
          child._yieldChild = void 0;
          return child;
        }
      }
      parent = parent._yieldChild;
    }
    return this._createController(controllerPath, params, parent);
  };

  return _yield;

})(Neck.Helper);

})();

;
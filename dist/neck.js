(function() {
  "use strict";
  var Neck, extend;
  extend = function(obj, extend) {
    var property, value;
    for (property in extend) {
      value = extend[property];
      if (!obj.hasOwnProperty(property)) {
        obj[property] = value;
      }
    }
    return obj;
  };
  Neck = {
    observers: [],
    components: [],
    attributePrefix: false,
    setup: function(el) {
      var observer,
        _this = this;
      this.observers.push(observer = new MutationObserver(function(mutations) {
        var mutation, node, _i, _j, _k, _len, _len1, _len2, _ref, _ref1;
        for (_i = 0, _len = mutations.length; _i < _len; _i++) {
          mutation = mutations[_i];
          _ref = mutation.addedNodes;
          for (_j = 0, _len1 = _ref.length; _j < _len1; _j++) {
            node = _ref[_j];
            _this.compile(node);
          }
          _ref1 = mutation.removedNodes;
          for (_k = 0, _len2 = _ref1.length; _k < _len2; _k++) {
            node = _ref1[_k];
            _this.remove(node);
          }
        }
      }));
      observer.observe(el, {
        childList: true,
        subtree: true
      });
      return el;
    },
    compile: function(el) {
      if (node.nodeType === Node.ELEMENT_NODE) {
        return console.dir(el);
      }
    },
    remove: function(el) {
      return console.log("Removing el: " + el);
    }
  };
  document.registerNeckComponent = function(target, opts) {
    extend(opts, {
      priority: 0,
      target: target
    });
    if (opts.flags) {
      opts.flags = opts.flags.split(' ');
    }
    return Neck.components.push(options);
  };
  return root.addEventListener("DOMContentLoaded", function() {
    var el, _i, _len, _ref, _results;
    Neck.components.sort(function(a, b) {
      return b.priority - a.priority;
    });
    _ref = document.querySelectorAll('[neck]');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      el = _ref[_i];
      _results.push(Neck.setup(el));
    }
    return _results;
  });
})();
;(function() {
  return document.registerNeckComponent('template[something]', {
    compile: function() {}
  });
})();
;
//# sourceMappingURL=neck.js.map
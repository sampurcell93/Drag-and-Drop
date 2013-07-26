// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(document).ready(function() {
    var allLayouts, _ref, _ref1, _ref2, _ref3, _ref4;
    allLayouts = [
      {
        type: 'Dynamic Layout',
        view: 'dynamicLayout'
      }, {
        type: 'Dynamic Container',
        view: 'dynamicContainer'
      }, {
        type: 'Tabs',
        view: 'tabs'
      }, {
        type: 'Accordion',
        view: 'accordion'
      }
    ];
    window.models.Layout = (function(_super) {
      __extends(Layout, _super);

      function Layout() {
        _ref = Layout.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      return Layout;

    })(window.models.Element);
    window.collections.Layouts = Backbone.Collection.extend({
      model: models.Layout
    });
    window.views.LayoutList = Backbone.View.extend({
      el: ".layout-types ul",
      template: $("#picker-interface").html(),
      initialize: function() {
        this.controller = this.options.controller;
        this.collection = new collections.Layouts(allLayouts);
        this.wrapper = $(".control-section").eq(this.controller.index);
        this.$el = this.wrapper.find(this.el);
        this.el = this.$el.get();
        return this.render();
      },
      render: function() {
        var $el;
        $el = this.$el;
        _.each(this.collection.models, function(layout) {
          return $el.append(new views.GenericListItem({
            model: layout
          }).render().el);
        });
        return this;
      }
    });
    window.views["dynamicLayout"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref1 = _Class.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      _Class.prototype.template = $("#dynamic-layout").html();

      _Class.prototype.initialize = function() {
        _.bindAll(this, "afterRender");
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.afterRender = function() {};

      return _Class;

    })(window.views["genericElement"]);
    window.views["dynamicContainer"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref2 = _Class.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      _Class.prototype.template = $("#dynamic-container").html();

      _Class.prototype.initialize = function() {
        _.bindAll(this, "afterRender");
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.afterRender = function() {};

      return _Class;

    })(window.views["genericElement"]);
    window.views["accordion"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref3 = _Class.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      _Class.prototype.template = $("#accordion-layout").html();

      _Class.prototype.initialize = function() {
        _.bindAll(this, "afterRender");
        this.listenTo(this.model.get("child_els"), 'add', function(m, c, o) {
          return console.log("added, overwrite");
        });
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.afterRender = function() {
        if ((this.model.get("child_els").length)) {
          return this.$el.children(".placeholder").remove();
        }
      };

      return _Class;

    })(window.views["genericElement"]);
    return window.views["tabs"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref4 = _Class.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      _Class.prototype.template = $("#tab-layout").html();

      _Class.prototype.initialize = function() {
        _.bindAll(this, "afterRender");
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.afterRender = function() {};

      return _Class;

    })(window.views["genericElement"]);
  });

}).call(this);

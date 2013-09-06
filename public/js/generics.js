// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(document).ready(function() {
    var generics, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
    generics = [
      {
        "type": "Button",
        "view": "Button"
      }, {
        "type": "Custom Text",
        "view": "CustomText"
      }, {
        "type": "Custom Header",
        "view": "CustomHeader"
      }, {
        type: 'Input Field',
        view: "Input"
      }, {
        type: 'Date/Time',
        view: 'DateTime'
      }, {
        type: 'Radio',
        view: 'Radio'
      }, {
        type: 'Link',
        view: 'Link'
      }, {
        type: 'Dropdown',
        view: 'Dropdown'
      }
    ];
    window.models.GenericElement = Backbone.Model.extend({});
    window.collections.GenericElements = Backbone.Collection.extend({
      model: models.GenericElement,
      url: '/generic'
    });
    window.views.GenericList = Backbone.View.extend({
      el: ".generic-elements ul",
      initialize: function() {
        this.controller = this.options.controller;
        this.collection = new collections.GenericElements(generics);
        this.wrapper = $(".control-section").eq(this.controller.index);
        this.$el = this.wrapper.find(".generic-elements ul");
        this.el = this.$el.get();
        return this.render();
      },
      render: function() {
        var $el;
        $el = this.$el;
        _.each(this.collection.models, function(el) {
          return $el.append(new views.OutsideDraggableItem({
            model: el
          }).render().el);
        });
        return this;
      }
    });
    window.views.OutsideDraggableItem = Backbone.View.extend({
      initialize: function() {
        var baseModel, self;
        baseModel = this.model.toJSON();
        self = this;
        return this.$el.draggable({
          revert: true,
          helper: "clone",
          cursor: "move",
          start: function(e, ui) {
            var child_els, toAdd;
            $(ui.helper).addClass("dragging");
            child_els = new collections.Elements();
            toAdd = new models.Element(baseModel);
            child_els.model = toAdd;
            toAdd.set("child_els", child_els);
            return window.currentDraggingModel = toAdd;
          },
          stop: function(e, ui) {
            $(ui.item).removeClass("dragging").remove();
            if (ui.helper.data('dropped') === true) {
              return $(e.target).remove();
            }
          }
        });
      },
      template: $("#generic-element").html(),
      tagName: 'li',
      render: function() {
        var $el;
        $el = this.$el.addClass("generic-item");
        $el.html(_.template(this.template, this.model.toJSON()));
        return this;
      },
      events: {
        "click": function() {
          var child_els, toAdd;
          child_els = new collections.Elements();
          toAdd = new models.Element(this.model.toJSON());
          child_els.model = toAdd;
          toAdd.set("child_els", child_els, {
            no_history: true
          });
          console.log(allSections.at(window.currIndex));
          return allSections.at(window.currIndex).get("builder").scaffold.get("child_els").add(toAdd, {
            at: 0,
            no_history: true
          });
        }
      }
    });
    window.views.genericElement = (function(_super) {
      __extends(genericElement, _super);

      function genericElement() {
        _ref = genericElement.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      genericElement.prototype.initialize = function(options) {
        var self;
        genericElement.__super__.initialize.apply(this, arguments);
        $.extend(this.events, {
          "keyup .title-setter": function(e) {
            this.model.set('title', $(e.currentTarget).val(), {
              no_history: true
            });
            return e.stopPropagation();
          }
        });
        self = this;
        return this.model.on("change:title", function(model) {
          return self.$el.find(".label-text").first().text(self.model.get("title"));
        });
      };

      return genericElement;

    })(window.views.draggableElement);
    views["Input"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref1 = _Class.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      _Class.prototype.template = $("#input-template").html();

      _Class.prototype.className = 'builder-element w5';

      _Class.prototype.initialize = function() {
        var self;
        _Class.__super__.initialize.apply(this, arguments);
        self = this;
        return this.model.on("change:editable", function() {
          return self.render();
        });
      };

      return _Class;

    })(views.genericElement);
    window.views['Button'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref2 = _Class.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      _Class.prototype.template = $("#button-template").html();

      return _Class;

    })(window.views.genericElement);
    window.views['CustomHeader'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref3 = _Class.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      _Class.prototype.template = $("#custom-header").html();

      return _Class;

    })(window.views.genericElement);
    window.views['CustomText'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref4 = _Class.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      _Class.prototype.template = $("#custom-text").html();

      return _Class;

    })(window.views.genericElement);
    window.views['Radio'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref5 = _Class.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      _Class.prototype.template = $("#generic-radio").html();

      _Class.prototype.initialize = function(options) {
        _Class.__super__.initialize.apply(this, arguments);
        return this.model.on({
          "change:label_position": this.render,
          "change:label_text": this.render
        });
      };

      return _Class;

    })(window.views.genericElement);
    window.views['Link'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref6 = _Class.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      _Class.prototype.template = $("#custom-link").html();

      return _Class;

    })(window.views.genericElement);
    window.views['DateTime'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref7 = _Class.__super__.constructor.apply(this, arguments);
        return _ref7;
      }

      _Class.prototype.template = $("#date-time").html();

      _Class.prototype.initialize = function(options) {
        _.bindAll(this, "afterRender");
        if (typeof this.model.get("display") === "undefined") {
          this.model.set("display", "full", {
            silent: true
          });
        }
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.afterRender = function() {
        return this.$(".date-picker").first().datepicker();
      };

      return _Class;

    })(window.views.genericElement);
    window.views['Dropdown'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref8 = _Class.__super__.constructor.apply(this, arguments);
        return _ref8;
      }

      _Class.prototype.template = $("#dropdown").html();

      return _Class;

    })(window.views.genericElement);
    return window.views['TableCell'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref9 = _Class.__super__.constructor.apply(this, arguments);
        return _ref9;
      }

      _Class.prototype.tagName = 'td class="builder-element"';

      return _Class;

    })(window.views.genericElement);
  });

}).call(this);

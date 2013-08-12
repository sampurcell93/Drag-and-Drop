// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(document).ready(function() {
    var generics, _ref, _ref1, _ref10, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
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
        this.$el = this.wrapper.find(this.el);
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
            window.currentDraggingModel = toAdd;
            return console.log(toAdd === self.model);
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
      }
    });
    window.views.genericElement = (function(_super) {
      __extends(genericElement, _super);

      function genericElement() {
        _ref = genericElement.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      genericElement.prototype.initialize = function(options) {
        genericElement.__super__.initialize.apply(this, arguments);
        return $.extend(this.events, {
          "keyup .title-setter": function(e) {
            this.model.set('title', $(e.currentTarget).val(), {
              no_history: true
            });
            return e.stopPropagation();
          }
        });
      };

      return genericElement;

    })(window.views.draggableElement);
    views["Property"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref1 = _Class.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      _Class.prototype.template = $("#property-template").html();

      return _Class;

    })(views.genericElement);
    window.views['Button'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref2 = _Class.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      _Class.prototype.template = $("#button-template").html();

      _Class.prototype.initialize = function(options) {
        var self;
        _Class.__super__.initialize.apply(this, arguments);
        self = this;
        return this.model.on("change:title", function(model) {
          return self.$el.children(".title-setter").text(model.get("title"));
        });
      };

      return _Class;

    })(window.views.genericElement);
    window.views['CustomHeader'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref3 = _Class.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      _Class.prototype.template = $("#custom-header").html();

      _Class.prototype.initialize = function(options) {
        return _Class.__super__.initialize.apply(this, arguments);
      };

      return _Class;

    })(window.views.genericElement);
    window.views['CustomText'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref4 = _Class.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      _Class.prototype.template = $("#custom-text").html();

      _Class.prototype.initialize = function(options) {
        return _Class.__super__.initialize.apply(this, arguments);
      };

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
        var self;
        _Class.__super__.initialize.apply(this, arguments);
        self = this;
        _.bindAll(this, "afterRender");
        return this.model.on({
          "change:label_position": this.render,
          "change:label_text": this.render
        });
      };

      _Class.prototype.afterRender = function() {
        var label_position;
        console.log("just rendered radio");
        label_position = this.model.get("label_position");
        if (label_position === "top" || label_position === "bottom") {
          return console.log(this.$el.find("span.label-text").css("display", "block"));
        }
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

      _Class.prototype.initialize = function(options) {
        return _Class.__super__.initialize.apply(this, arguments);
      };

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
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.afterRender = function() {
        return this.$el.find(".date-picker").datepicker();
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

      _Class.prototype.initialize = function(options) {
        return _Class.__super__.initialize.apply(this, arguments);
      };

      return _Class;

    })(window.views.genericElement);
    window.views['TableCell'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref9 = _Class.__super__.constructor.apply(this, arguments);
        return _ref9;
      }

      _Class.prototype.tagName = 'td class="builder-element"';

      _Class.prototype.initialize = function(options) {
        return _Class.__super__.initialize.apply(this, arguments);
      };

      return _Class;

    })(window.views.genericElement);
    return window.views['BuilderWrapper'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref10 = _Class.__super__.constructor.apply(this, arguments);
        return _ref10;
      }

      _Class.prototype.controls = null;

      _Class.prototype.contextMenu = null;

      _Class.prototype.initialize = function() {
        var self;
        _Class.__super__.initialize.apply(this, arguments);
        self = this;
        _.bindAll(this, "afterRender");
        if (this.model.get("child_els").length === 0) {
          $("<p/>").text("Drop UI Elements, layouts, and other sections here to start building!").addClass("placeholder p10 center mauto").appendTo(this.$el);
        }
        return this.model.on({
          "render": function() {
            return self.render(true);
          }
        });
      };

      _Class.prototype.template = $("#builder-wrap").html();

      _Class.prototype.appendChild = function() {
        _Class.__super__.appendChild.apply(this, arguments);
        if (this.model.get("child_els").length === 0) {
          return $("<p/>").text("Drop UI Elements, layouts, and other sections here to start building!").addClass("placeholder p10 center mauto").appendTo(this.$el);
        } else {
          return this.$el.children(".placeholder").remove();
        }
      };

      _Class.prototype.bindDrag = function() {};

      _Class.prototype.afterRender = function() {
        var that;
        that = this;
        this.$el.selectable({
          filter: '.builder-element:not(.builder-scaffold)',
          tolerance: 'touch',
          cancel: ".config-menu-wrap, input, .title-setter, textarea, .no-drag, .context-menu",
          stop: function(e) {
            if (e.shiftKey === true) {
              return that.blankLayout();
            }
          },
          selecting: function(e, ui) {
            return $(ui.selecting).trigger("select");
          },
          unselecting: function(e, ui) {
            var $item;
            if (e.shiftKey === true) {
              return;
            }
            $item = $(ui.unselecting);
            return $item.trigger("deselect");
          }
        });
        return this.$el.addClass("builder-scaffold");
      };

      return _Class;

    })(window.views.genericElement);
  });

}).call(this);

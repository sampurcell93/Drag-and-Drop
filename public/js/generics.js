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
        "tagName": "ol",
        "type": "Numbered List",
        "view": "listElement",
        listItems: [1, 2, 3]
      }, {
        "tagName": "ul",
        "type": "Bulleted List",
        "view": "listElement",
        listItems: [1, 2, 3]
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
            console.log("title");
            this.model.set({
              'customHeader': $(e.currentTarget).val(),
              'title': $(e.currentTarget).val()
            });
            return e.stopPropagation();
          }
        });
      };

      return genericElement;

    })(window.views.draggableElement);
    window.views['listElement'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref1 = _Class.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      _Class.prototype.template = $("#generic-list").html();

      _Class.prototype.initialize = function(options) {
        _Class.__super__.initialize.apply(this, arguments);
        console.log(this.events);
        return $.extend(this.events, {
          "click .add-list-item": function(e) {
            var genericList, index, innerText;
            genericList = this.$el.find(".generic-list");
            index = genericList.children().length;
            innerText = "Item " + (index + 1);
            $("<li/>").text(innerText).attr("contenteditable", true).appendTo(genericList);
            this.model.updateListItems(innerText, index);
            e.stopPropagation();
            return console.log(this.events);
          },
          "keyup .generic-list li": function(e) {
            var index, keyCode, target;
            keyCode = e.keyCode || e.which;
            target = $(e.currentTarget);
            index = target.index();
            if (target.index() === 0) {
              this.model.set("title", target.text());
            }
            return this.updateListItems(target.html(), index);
          },
          "click .remove-property-link": function(e) {
            return $(e.currentTarget).closest(".property-link").slideUp("fast", function() {
              return $(this).remove();
            });
          }
        });
      };

      _Class.prototype.updateListItems = function(text, index) {
        var listItems;
        if (this.model.get("type") === "Numbered List" || this.model.get("type") === "Bulleted List") {
          listItems = this.model.get("listItems");
          if (listItems != null) {
            listItems[index] = {};
            listItems[index].text = text;
          } else {
            listItems.splice(index, 0, {
              text: text
            });
          }
          return this.model.set("listItems", listItems);
        }
      };

      return _Class;

    })(window.views.genericElement);
    window.views['Button'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref2 = _Class.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      _Class.prototype.template = $("#button-template").html();

      _Class.prototype.initialize = function(options) {
        _Class.__super__.initialize.apply(this, arguments);
        return _.bindAll(this, "beforeRender");
      };

      _Class.prototype.beforeRender = function() {
        return this.$el.addClass("max-w3");
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
        return _Class.__super__.initialize.apply(this, arguments);
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
    return window.views['BuilderWrapper'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref9 = _Class.__super__.constructor.apply(this, arguments);
        return _ref9;
      }

      _Class.prototype.controls = null;

      _Class.prototype.initialize = function() {
        _Class.__super__.initialize.apply(this, arguments);
        return _.bindAll(this, "afterRender");
      };

      _Class.prototype.template = $("#builder-wrap").html();

      _Class.prototype.bindDrag = function() {
        return null;
      };

      _Class.prototype.afterRender = function() {
        var that;
        that = this;
        this.$el.selectable({
          filter: '.builder-element:not(.builder-scaffold)',
          tolerance: 'touch',
          cancel: ".config-menu-wrap, input, .title-setter, textarea, .no-drag",
          stop: function(e, ui) {
            var collection, layout, layoutIndex, selected;
            if (e.shiftKey === false) {
              return;
            }
            collection = that.model.get("child_els");
            selected = collection.gather();
            if (selected.length === 0 || selected.length === 1) {
              return;
            }
            layoutIndex = collection.indexOf(selected[0]);
            collection.add(layout = new models.Element({
              view: 'BlankLayout',
              type: 'Blank Layout'
            }), {
              at: layoutIndex
            });
            return _.each(selected, function(model) {
              if (model.collection != null) {
                model.collection.remove(model);
              }
              return layout.get("child_els").add(model);
            });
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
            $item.trigger("deselect");
            return that.$el.find(".selected-element").trigger("deselect");
          }
        });
        return this.$el.addClass("builder-scaffold");
      };

      return _Class;

    })(window.views.genericElement);
  });

}).call(this);

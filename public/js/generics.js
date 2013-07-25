// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(document).ready(function() {
    var _ref, _ref1, _ref2, _ref3, _ref4;
    window.models.GenericElement = Backbone.Model.extend({
      defaults: function() {
        return {
          listItems: [1, 2, 3]
        };
      }
    });
    window.collections.GenericElements = Backbone.Collection.extend({
      model: models.GenericElement,
      url: '/generic'
    });
    window.views.GenericList = Backbone.View.extend({
      initialize: function() {
        this.controller = this.options.controller;
        this.wrapper = $(".control-section").eq(this.controller.index);
        this.$el = this.wrapper.find(".generic-elements ul");
        console.log(this.controller.index);
        return this.render();
      },
      render: function() {
        var $el;
        $el = this.$el;
        _.each(this.collection.models, function(el) {
          return $el.append(new views.GenericListItem({
            model: el
          }).render().el);
        });
        return this;
      }
    });
    window.views.GenericListItem = Backbone.View.extend({
      initialize: function() {
        var child_els, self;
        child_els = new collections.Elements();
        child_els.model = this.model;
        this.model.set("child_els", child_els);
        this.baseModel = this.model.toJSON();
        self = this;
        return this.$el.draggable({
          revert: true,
          helper: function() {
            return new window.views[self.model.get("view")]({
              model: self.model
            }).render().el;
          },
          cursor: "move",
          start: function(e, ui) {
            var toAdd;
            $(ui.helper).addClass("dragging");
            toAdd = new models.Element(self.model.toJSON());
            console.log(toAdd);
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
            return this.model.updateListItems(target.html(), index);
          },
          "click .remove-property-link": function(e) {
            return $(e.currentTarget).closest(".property-link").slideUp("fast", function() {
              return $(this).remove();
            });
          }
        });
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
        console.log(this.events);
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
    return window.views['CustomText'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref4 = _Class.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      _Class.prototype.template = $("#custom-text").html();

      _Class.prototype.initialize = function(options) {
        _Class.__super__.initialize.apply(this, arguments);
        return console.log("making customtext with index", this.index);
      };

      return _Class;

    })(window.views.genericElement);
  });

}).call(this);

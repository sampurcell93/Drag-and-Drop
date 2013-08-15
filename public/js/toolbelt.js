// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var toolbelt, _ref;
    toolbelt = window.views.toolbelt = {};
    return toolbelt.Actives = (function(_super) {
      __extends(Actives, _super);

      function Actives() {
        _ref = Actives.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Actives.prototype.tagName = 'ul';

      Actives.prototype.initialize = function() {
        return this.listenTo(this.model, {
          "change": this.render,
          "remove": this.remove
        });
      };

      Actives.prototype.render = function() {
        this.quickAttrs();
        return this;
      };

      Actives.prototype.getProps = function(attrs) {
        var prop, properties, property_item;
        property_item = "<li data-attr='<%=prop%>'><%=prop.clean() %>: <%= value %></li>";
        properties = "";
        for (prop in attrs) {
          if (this.regard.indexOf(prop) !== -1) {
            properties += _.template(property_item, {
              prop: prop,
              value: this.formatAttributes(attrs[prop])
            });
          }
        }
        return properties;
      };

      Actives.prototype.regard = ["child_els", "title", "type"];

      Actives.prototype.editables = ["title"];

      Actives.prototype.quickAttrs = function(e) {
        var attrs, properties;
        if (this.$el.hasClass("builder-scaffold")) {
          return false;
        }
        attrs = this.model.attributes;
        properties = this.getProps(attrs);
        return this.$el.html(properties);
      };

      Actives.prototype.formatAttributes = function(data) {
        var items;
        if (typeof data === "string") {
          return "<span contentEditable>" + data + "</span>";
        } else if ($.isArray(data)) {
          items = "";
          if (data.length === 0) {
            return "None";
          }
          _.each(data, function(item) {
            return items += "<span style='color: red'>" + item + "</span>";
          });
          return items;
        } else {
          return this.formatObject(data.models);
        }
      };

      Actives.prototype.formatObject = function(obj) {
        var items, self;
        if (obj == null) {
          return "";
        }
        self = this;
        items = "<div class='close-arrow icon-uniF48A'></div><ul class='hidden'>";
        if (obj.length === 0) {
          return "None";
        }
        _.each(obj, function(model) {
          return items += "<li>" + self.getProps(model.attributes) + "</li>";
        });
        items += "</ul></div>";
        return items;
      };

      Actives.prototype.events = {
        "keyup [data-attr] span": function(e) {
          var $t, attr, val;
          $t = $(e.currentTarget);
          attr = $t.closest("[data-attr]").data("attr");
          val = $t.html();
          this.model.set(attr, val, {
            no_history: true
          });
          return e.stopPropagation();
        }
      };

      return Actives;

    })(Backbone.View);
  });

}).call(this);

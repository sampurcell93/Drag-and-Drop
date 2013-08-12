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

      Actives.prototype.el = ".quick-props";

      Actives.prototype.initialize = function() {
        this.listenTo(this.model, "change", this.quickAttrs);
        return this.listenTo(this.model.get("child_els", "change", this.quickAttrs));
      };

      Actives.prototype.render = function() {
        return this.quickAttrs();
      };

      Actives.prototype.getProps = function(attrs) {
        var prop, properties, property_item;
        property_item = "<li data-attr='<%=prop%>'><%=prop.clean() %>: <%= value %></li>";
        properties = "";
        for (prop in attrs) {
          if (this.disregardAttrs.indexOf(prop) === -1) {
            properties += _.template(property_item, {
              prop: prop,
              value: this.formatAttributes(attrs[prop])
            });
          }
        }
        return properties;
      };

      Actives.prototype.disregardAttrs = ["inFlow", "view", "styles", "property"];

      Actives.prototype.quickAttrs = function(e) {
        var attrs, properties;
        if (this.$el.hasClass("builder-scaffold")) {
          return false;
        }
        properties = "<ul>";
        attrs = this.model.attributes;
        properties += this.getProps(attrs);
        properties += "</ul>";
        return $(".quick-props").find("ul").html(properties);
      };

      Actives.prototype.formatAttributes = function(data) {
        var items;
        if (typeof data === "string") {
          return data;
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
        items = "<div class='close-arrow pointer'>p</div><ul class='hidden'>";
        if (obj.length === 0) {
          return "None";
        }
        _.each(obj, function(model) {
          return items += "<li>" + self.getProps(model.attributes) + "</li>";
        });
        items += "</ul></div>";
        return items;
      };

      return Actives;

    })(Backbone.View);
  });

}).call(this);

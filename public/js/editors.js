// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var editors, _ref, _ref1;
    editors = window.views.editors = {};
    editors["DefaultEditor"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref = _Class.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      _Class.prototype.initialize = function() {};

      _Class.prototype.render = function() {
        var modal;
        console.log("default rendwer");
        modal = window.launchModal("yolo");
        return (this.afterRender || function() {
          return {};
        })();
      };

      return _Class;

    })(Backbone.View);
    return editors["Button"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref1 = _Class.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      _Class.prototype.initialize = function() {
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.render = function() {
        _Class.__super__.render.apply(this, arguments);
        return console.log("button render");
      };

      return _Class;

    })(editors["DefaultEditor"]);
  });

}).call(this);
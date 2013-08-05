// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var editors, _ref, _ref1, _ref2, _ref3, _ref4, _ref5;
    editors = window.views.editors = {};
    editors["BaseEditor"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref = _Class.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      _Class.prototype.change_queue = [];

      _Class.prototype.tagName = "div class='modal'";

      _Class.prototype.standards = [$("#change-styles").html()];

      _Class.prototype.initialize = function() {
        this.change_queue = [];
        if (this.templates == null) {
          this.templates = [];
        }
        return this.templates = this.templates.concat(this.standards);
      };

      _Class.prototype.render = function() {
        var editor_content, self;
        self = this;
        this.link_el = this.options.link_el;
        editor_content = "";
        this.templates = this.templates.concat([$("#finalize-editing").html()]);
        _.each(this.templates, function(template) {
          console.log(self.model.toJSON());
          return editor_content += _.template(template, self.model.toJSON());
        });
        return this.$el.appendTo(document.body).html(editor_content);
      };

      _Class.prototype.enqueue = function(name, func, opts) {
        var index, prevDeclaration, queue;
        queue = this.change_queue;
        prevDeclaration = _.findWhere(queue, {
          name: name
        });
        if (prevDeclaration != null) {
          index = queue.indexOf(prevDeclaration);
          queue[index] = prevDeclaration;
          return;
        }
        if ((opts != null) && opts.pushBack === true) {
          return queue.pushBack({
            name: name,
            func: func
          });
        } else {
          return queue.push({
            name: name,
            func: func
          });
        }
      };

      _Class.prototype.events = {
        "change .set-width": function(e) {
          var self, width;
          width = $(e.currentTarget).val();
          self = this;
          console.log;
          return this.enqueue("width-change", function() {
            var classes;
            $(self.link_el).addClass(width);
            classes = self.model.get("classes");
            classes.push(width);
            return self.model.set("classes", classes);
          });
        },
        "keyup .title-setter": function() {
          var self;
          self = this;
          return this.enqueue("title", function() {
            return self.model.set("title", self.$el.find(".title-setter").val());
          });
        },
        "click .confirm": function() {
          var cq, process, _results;
          cq = this.change_queue;
          _results = [];
          for (process in cq) {
            _results.push(process = cq[process].func());
          }
          return _results;
        },
        "click .reject, .confirm": function() {
          $(document.body).removeClass("active-modal");
          return this.remove();
        }
      };

      return _Class;

    })(Backbone.View);
    editors["BaseLayoutEditor"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref1 = _Class.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      _Class.prototype.standards = [$("#layout-changer").html(), $("#skins").html(), $("#column-picker").html()];

      _Class.prototype.initialize = function() {
        if (this.templates == null) {
          this.templates = [];
        }
        this.templates = this.templates.concat(this.standards);
        return _.extend(this.events, {
          "click [data-columns]": function(e) {
            var $t, cols, coltypes, self;
            coltypes = ["two", "three", "four", "five", "six"];
            $t = $(e.currentTarget);
            cols = $t.data("columns");
            self = this;
            $t.addClass("selected-choice").siblings().removeClass("selected-choice");
            if (this.model != null) {
              this.enqueue("columns", function() {
                return self.model.set("columns", cols);
              });
            }
            _.each(coltypes, function(type) {
              return self.enqueue("remove_col_classes-" + type, function() {
                return $(self.link_el).removeClass("column " + type);
              });
            });
            if (cols !== "") {
              return this.enqueue("add_col_classes", function() {
                return $(self.link_el).addClass("column " + cols);
              });
            }
          },
          "click [data-layout]": function(e) {
            var $t, layout, self;
            $t = $(e.currentTarget);
            layout = $t.data("layout");
            self = this;
            $t.addClass("selected-choice").siblings().removeClass("selected-choice");
            return this.enqueue("view", function() {
              self.model.set({
                "layout": true,
                "view": layout
              });
              return $(self.link_el).addClass("tab-layout");
            });
          }
        });
      };

      return _Class;

    })(editors["BaseEditor"]);
    editors["Button"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref2 = _Class.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      _Class.prototype.templates = [$("#button-editor").html()];

      return _Class;

    })(editors["BaseEditor"]);
    editors['Link'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref3 = _Class.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      _Class.prototype.templates = [$("#link-editor").html()];

      _Class.prototype.initialize = function() {};

      return _Class;

    })(editors["BaseEditor"]);
    editors['Radio'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref4 = _Class.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      _Class.prototype.templates = [$("#radio-editor").html()];

      _Class.prototype.initialize = function() {
        var self;
        _Class.__super__.initialize.apply(this, arguments);
        self = this;
        return _.extend(this.events, {
          "change .label-position": function(e) {
            var position;
            position = $(e.currentTarget).val();
            return self.enqueue("label_position", function() {
              return self.model.set("label_position", position);
            });
          }
        });
      };

      return _Class;

    })(editors["BaseEditor"]);
    return editors["accordion"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref5 = _Class.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      _Class.prototype.templates = [$("#accordion-layout").html()];

      return _Class;

    })(editors["BaseLayoutEditor"]);
  });

}).call(this);

// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(function() {
    var editors, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7;
    editors = window.views.editors = {};
    editors["BaseEditor"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref = _Class.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      _Class.prototype.change_queue = [];

      _Class.prototype.tagName = "div class='modal'";

      _Class.prototype.templates = [
        {
          tab: 'Element Styling',
          templates: [$("#change-styles").html()]
        }
      ];

      _Class.prototype.render = function() {
        var editor_content, self, tabs;
        self = this;
        this.link_el = this.options.link_el;
        editor_content = "<ul class='tabs'>";
        tabs = _.pluck(this.templates, "tab");
        _.each(tabs, function(tab, i) {
          var sel;
          if (i === 0) {
            sel = "current-tab";
          } else {
            sel = "";
          }
          return editor_content += "<li class='" + sel + "' rel='" + tab.dirty() + "'>" + tab + "</li>";
        });
        editor_content += "</ul>";
        _.each(this.templates, function(tabcontent, i) {
          editor_content += "<div class='modal-tab' id='" + tabcontent.tab.dirty() + "'>";
          _.each(tabcontent.templates, function(template) {
            return editor_content += _.template(template, self.model.toJSON());
          });
          editor_content += "</div>";
          return true;
        });
        editor_content += _.template($("#finalize-editing").html(), {});
        return this.$el.appendTo(document.body).html(editor_content);
      };

      _Class.prototype.enqueue = function(name, func) {
        return this.change_queue[name] = func;
      };

      _Class.prototype.addTemplate = function(template, index, inner_index) {
        if (!inner_index) {
          return this.templates[index].templates.push(template);
        } else {
          return this.templates[index].templates.splice(inner_index, 0, template);
        }
      };

      _Class.prototype.addTab = function(obj, index) {
        if (index != null) {
          return this.templates.splice(index, 0, obj);
        } else {
          return this.templates.push(obj);
        }
      };

      _Class.prototype.events = {
        "change [data-attr]": function(e) {
          var $t, attr, parsed, self, val;
          $t = $(e.currentTarget);
          attr = $t.data("attr");
          val = $t.val();
          self = this;
          parsed = val.parseBool();
          if (parsed === null) {
            parsed = val;
          }
          this.enqueue(attr, function() {
            return self.model.set(attr, parsed);
          });
          return e.stopPropagation();
        },
        "change .set-width": function(e) {
          var self, width;
          width = $(e.currentTarget).val();
          self = this;
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
            return self.model.set("title", self.$el.find(".title-setter").val(), {
              no_history: true
            });
          });
        },
        "click .confirm": function() {
          var cq, process, _results;
          cq = this.change_queue;
          _results = [];
          for (process in cq) {
            _results.push(process = cq[process]());
          }
          return _results;
        },
        "click .reject, .confirm": function() {
          $(document.body).removeClass("active-modal");
          this.change_queue = [];
          return this.remove();
        },
        "click .tabs li": function(e) {
          var $el, $t, rel;
          $t = $(e.currentTarget);
          $el = this.$el;
          rel = "#" + $t.attr("rel");
          this.$(".modal-tab").not(rel).hide();
          $(rel).show();
          return $t.addClass("current-tab").siblings().removeClass("current-tab");
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

      _Class.prototype.templates = [
        {
          tab: 'Free Form Divisions',
          templates: [$("#column-picker").html()]
        }, {
          tab: 'Preset Layouts',
          templates: [$("#layout-changer").html(), $("#skins").html(), $("#preset-layouts").html()]
        }
      ];

      _Class.prototype.initialize = function() {
        return _.extend(this.events, {
          "click .select-one li": function(e) {
            return $(e.currentTarget).addClass("selected-choice").siblings().removeClass("selected-choice");
          },
          "click [data-columns]": function(e) {
            var $t, cols, coltypes, self;
            coltypes = ["two", "three", "four", "five", "six"];
            $t = $(e.currentTarget);
            cols = $t.data("columns");
            self = this;
            if (this.model != null) {
              this.enqueue("columns", function() {
                var classes;
                self.model.set("columns", cols);
                classes = self.model.get("classes");
                classes.push("column " + cols);
                return self.model.set("classes", classes);
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
            return this.enqueue("view", function() {
              self.model.set({
                "layout": true,
                "view": layout,
                type: "Tab Layout"
              });
              return $(self.link_el).addClass("tab-layout");
            });
          },
          "click .preset-layouts li": function(e) {
            var $t, className, classes, self;
            $t = $(e.currentTarget);
            className = $t.data("class");
            self = this;
            classes = this.model.get("classes");
            classes.push(className);
            return this.enqueue("presetlayout", function() {
              self.model.set("presetlayout", className);
              self.model.set("classes", classes);
              return $(self.link_el).addClass(className);
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

      _Class.prototype.render = function() {
        var modal;
        _Class.__super__.render.apply(this, arguments);
        this.cq = this.change_queue;
        modal = this.el || $(".modal").first();
        return this.$el = $(this.el);
      };

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
          },
          "keyup .label-text": function(e) {
            var label;
            label = $(e.currentTarget).val();
            return self.enqueue("label_text", function() {
              return self.model.set("title", label);
            });
          }
        });
      };

      return _Class;

    })(editors["BaseEditor"]);
    editors["DateTime"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref5 = _Class.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      _Class.prototype.templates = [$("#icon-or-full").html()];

      return _Class;

    })(editors["BaseEditor"]);
    editors["Property"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref6 = _Class.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      _Class.prototype.templates = [$("#property-editor").html()];

      return _Class;

    })(editors["BaseEditor"]);
    return editors["accordion"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref7 = _Class.__super__.constructor.apply(this, arguments);
        return _ref7;
      }

      _Class.prototype.templates = [$("#accordion-layout").html()];

      return _Class;

    })(editors["BaseLayoutEditor"]);
  });

}).call(this);

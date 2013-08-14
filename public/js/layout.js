// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(document).ready(function() {
    var adjs, allLayouts, nouns, randomDict, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8;
    adjs = ["autumn", "hidden", "bitter", "misty", "silent", "empty", "dry", "dark", "summer", "icy", "delicate", "quiet", "white", "cool", "spring", "winter", "patient", "twilight", "dawn", "crimson", "wispy", "weathered", "blue", "billowing", "broken", "cold", "damp", "falling", "frosty", "green", "long", "late", "lingering", "bold", "little", "morning", "muddy", "old", "red", "rough", "still", "small", "sparkling", "throbbing", "shy", "wandering", "withered", "wild", "black", "young", "holy", "solitary", "fragrant", "aged", "snowy", "proud", "floral", "restless", "divine", "polished", "ancient", "purple", "lively", "nameless", "protected", "fierce", "snowy", "floating", "serene", "placid", "afternoon", "calm", "cryptic", "desolate", "falling", "glacial", "limitless", "murmuring", "pacific", "whispering"];
    nouns = ["waterfall", "river", "breeze", "moon", "rain", "wind", "sea", "morning", "snow", "lake", "sunset", "pine", "shadow", "leaf", "dawn", "glitter", "forest", "hill", "cloud", "meadow", "sun", "glade", "bird", "brook", "butterfly", "bush", "dew", "dust", "field", "fire", "flower", "firefly", "feather", "grass", "haze", "mountain", "night", "pond", "darkness", "snowflake", "silence", "sound", "sky", "shape", "surf", "thunder", "violet", "water", "wildflower", "wave", "water", "resonance", "sun", "wood", "dream", "cherry", "tree", "fog", "frost", "voice", "paper", "frog", "smoke", "star", "savannah", "quarry", "mountainside", "riverbank", "canopy", "tree", "monastery", "frost", "shelf", "badlands", "crags", "lowlands", "badlands", "woodlands", "eyrie", "beach", "temple"];
    String.prototype.firstUpperCase = function() {
      return this.charAt(0).toUpperCase() + this.slice(1);
    };
    randomDict = function() {
      return (adjs[Math.floor(Math.random() * adjs.length)] + "-" + nouns[Math.floor(Math.random() * nouns.length)]).toLowerCase().firstUpperCase() + "-" + Math.floor(Math.random() * 10000);
    };
    allLayouts = [
      {
        type: 'Dynamic Layout',
        view: 'DynamicLayout'
      }, {
        type: 'Tabbed Layout',
        view: 'tabs'
      }, {
        type: 'List Layout',
        view: 'ListLayout'
      }, {
        type: 'Dynamic Grid',
        view: 'table'
      }, {
        type: 'Dynamic Repeating Layout',
        view: 'RepeatingLayout'
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
      template: $("#picker-interface").html(),
      initialize: function() {
        this.controller = this.options.controller;
        this.collection = new collections.Layouts(allLayouts);
        this.wrapper = $(".control-section").eq(this.controller.index);
        this.$el = this.wrapper.find(".layout-types ul");
        this.el = this.$el.get();
        return this.render();
      },
      render: function() {
        var $el;
        $el = this.$el;
        _.each(this.collection.models, function(layout) {
          return $el.append(new views.OutsideDraggableItem({
            model: layout
          }).render().el);
        });
        return this;
      }
    });
    window.views.layout = (function(_super) {
      __extends(layout, _super);

      function layout() {
        _ref1 = layout.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      layout.prototype.initialize = function() {
        var self;
        this.model.set("layout", true);
        layout.__super__.initialize.apply(this, arguments);
        self = this;
        _.bindAll(this, "afterRender", "bindDrop");
        this.$el.addClass("layout-wrapper");
        this.listenTo(this.model.get("child_els"), "add", function(m, c, o) {
          if ((c != null) && c.length) {
            return self.$el.children(".placeholder").hide();
          } else {
            return self.$el.children(".placeholder").show();
          }
        });
        _.extend(this.events, {
          "click .ungroup-fields": function() {
            var child, children, i, model, parent, position, _i, _len, _ref2;
            model = this.model;
            position = model.collection.indexOf(model);
            children = model.get("child_els");
            parent = model.collection;
            _ref2 = children.models;
            for (i = _i = 0, _len = _ref2.length; _i < _len; i = ++_i) {
              child = _ref2[i];
              child['layout-item'] = false;
              child.collection = null;
              parent.add(child, {
                at: position + i
              });
            }
            children.reset();
            return model.destroy();
          },
          "click .paste-element": function() {
            var copy;
            copy = window.copiedModel;
            if (copy != null) {
              window.copiedModel = copy.deepCopy();
              return this.model.get("child_els").add(copy);
            } else {
              return alert("Something went wrong.....");
            }
          }
        });
        this.bindDrop();
        return this;
      };

      layout.prototype.bindDrop = function() {
        var that;
        that = this;
        return this.$el.droppable({
          greedy: true,
          tolerance: 'pointer',
          accept: '.builder-element, .outside-draggables li, .property',
          over: function(e) {
            if ($(document.body).hasClass("active-modal")) {
              return false;
            }
            return $(e.target).addClass("over");
          },
          out: function(e) {
            return $(e.target).removeClass("over").parents().removeClass("over");
          },
          drop: function(e, ui) {
            var builder, draggingModel, model, sect_interface, section;
            $(e.target).removeClass("over").parents().removeClass("over");
            if ($(document.body).hasClass("active-modal")) {
              return false;
            }
            draggingModel = window.currentDraggingModel;
            if (typeof draggingModel === "undefined" || (draggingModel == null)) {
              return false;
            } else if (draggingModel === that.model) {
              return false;
            }
            sect_interface = allSections.at(that.index || currIndex);
            section = sect_interface.get("currentSection");
            builder = sect_interface.get("builder");
            model = that.model;
            if (draggingModel.collection !== model.get("child_els")) {
              if (model.blend(draggingModel) === true) {
                $(ui.helper).remove();
                ui.draggable.data('dropped', true);
                delete window.currentDraggingModel;
                window.currentDraggingModel = null;
              }
            }
            e.stopPropagation();
            e.stopImmediatePropagation();
            return true;
          }
        });
      };

      layout.prototype.afterRender = function() {
        if (this.model.get("child_els").length > 0) {
          return this.$el.children(".placeholder").hide();
        }
      };

      return layout;

    })(window.views.draggableElement);
    /* Inherited view events are triggered first - so if an indentical event binder is
        applied to a descendant, we can use event.stopPropagation() in order to stop the 
        higher level event from firing.
    */

    window.views['BuilderWrapper'] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref2 = _Class.__super__.constructor.apply(this, arguments);
        return _ref2;
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

    })(window.views.layout);
    views["table"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref3 = _Class.__super__.constructor.apply(this, arguments);
        return _ref3;
      }

      _Class.prototype.tagName = 'table';

      _Class.prototype.className = 'builder-element column six';

      _Class.prototype.template = $("#table-layout").html();

      _Class.prototype.initialize = function() {
        var self;
        _Class.__super__.initialize.apply(this, arguments);
        self = this;
        return this.model.get("child_els").on("add", function(model, collection, options) {
          if (model.get("type") !== "Property") {
            collection.remove(model);
            return self.model.collection.add(model);
          } else {
            model.set("view", "TableCell");
            console.log(self.$el.find(".dummy"));
            return self.$el.find(".dummy").first().append(self.dummyData());
          }
        });
      };

      _Class.prototype.dummyData = function() {
        var cell_template, col, cols, dummy, row, rows, _i, _j;
        cols = this.model.get("child_els").length;
        rows = 5;
        cell_template = "<td><%= word %></td>";
        dummy = "";
        for (row = _i = 0; 0 <= rows ? _i < rows : _i > rows; row = 0 <= rows ? ++_i : --_i) {
          if (row > 0) {
            dummy += "<tr>";
          }
          for (col = _j = 0; 0 <= cols ? _j < cols : _j > cols; col = 0 <= cols ? ++_j : --_j) {
            dummy += _.template(cell_template, {
              word: randomDict()
            });
          }
          if (row > 0) {
            dummy += "</tr>";
          }
        }
        return dummy;
      };

      return _Class;

    })(views["layout"]);
    window.views["DynamicLayout"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref4 = _Class.__super__.constructor.apply(this, arguments);
        return _ref4;
      }

      _Class.prototype.configTemplate = $("#dynamic-layout-setup").html();

      _Class.prototype.template = $("#dynamic-layout").html();

      _Class.prototype.initialize = function() {
        _.bindAll(this, "afterRender");
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.afterRender = function() {
        return this.$el.addClass("blank-layout");
      };

      return _Class;

    })(window.views["layout"]);
    window.views["dynamicContainer"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref5 = _Class.__super__.constructor.apply(this, arguments);
        return _ref5;
      }

      _Class.prototype.template = $("#dynamic-container").html();

      _Class.prototype.initialize = function() {
        _.bindAll(this, "afterRender");
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.afterRender = function() {};

      return _Class;

    })(window.views["layout"]);
    window.views["tabItem"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref6 = _Class.__super__.constructor.apply(this, arguments);
        return _ref6;
      }

      _Class.prototype.events = {
        "keyup h3:first-child": function(e) {
          var $t;
          $t = $(e.currentTarget);
          console.log($t);
          return this.model.set("title", $t.text());
        },
        "click": "showTabContent"
      };

      _Class.prototype.tabOffset = function() {
        var $el, column_types, len, num_per_row;
        len = this.model.collection.length;
        $el = this.$el;
        num_per_row = 0;
        column_types = ["two", "three", "four", "five", "six"];
        _.each(column_types, function(num, i) {
          if ($el.closest(".tab-layout").hasClass("column " + num)) {
            return num_per_row = i + 2;
          }
        });
        return 10 + 50 * (len / num_per_row);
      };

      _Class.prototype.initialize = function() {
        var self;
        _Class.__super__.initialize.apply(this, arguments);
        self = this;
        console.log("making new tab item");
        _.bindAll(this, "afterRender", "showTabContent");
        return this.model.get("child_els").on({
          "remove": this.showTabContent
        });
      };

      _Class.prototype.appendChild = function(model) {
        _Class.__super__.appendChild.apply(this, arguments);
        return this.$el.children("h3").first().trigger("click");
      };

      _Class.prototype.afterRender = function() {
        return this.$el.css("display", "inline-block !important").children("h3").first().attr("contentEditable", true).addClass("no-drag").trigger("click");
      };

      _Class.prototype.showTabContent = function() {
        var $el, offset, wrap_height;
        console.log("showTabContent");
        $el = this.$el;
        offset = this.tabOffset();
        console.log(offset);
        $el.children(".children").css({
          "top": 20 + offset + "px"
        });
        $el.addClass("active-tab").siblings().removeClass("active-tab");
        wrap_height = $el.height() + $el.children(".children").height();
        console.log(wrap_height);
        $el.closest(".tab-layout").css("height", wrap_height + offset + 12 + "px");
        console.log("done", $el.height() + $el.children(".children").height());
        return this.$el.children(".config-menu-wrap").css({
          "top": (offset - 10) + "px",
          "right": "26px"
        });
      };

      return _Class;

    })(views["draggableElement"]);
    window.views["tabs"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref7 = _Class.__super__.constructor.apply(this, arguments);
        return _ref7;
      }

      _Class.prototype.template = $("#tab-layout").html();

      _Class.prototype.itemName = 'tabItem';

      _Class.prototype.tagName = 'div class="builder-element tab-layout column six"';

      _Class.prototype.initialize = function() {
        var self;
        this.model.set("type", "Tab Layout");
        _.bindAll(this, "afterRender");
        self = this;
        this.listenTo(this.model.get("child_els"), {
          "remove": function(m, c, o) {
            if (c.length === 0) {
              return self.$el.children(".placeholder-text").show();
            }
          }
        });
        this.model.get("child_els").on("add", function() {
          cc("addd ON");
          return self.$el.children(".placeholder-text").hide();
        });
        return _Class.__super__.initialize.apply(this, arguments);
      };

      _Class.prototype.afterRender = function() {
        var self, tabs;
        cc("tabs after rendering");
        tabs = this.model.get("child_els");
        self = this;
        console.log(tabs.models);
        return _.each(tabs.models, function(tab) {
          return self.formatNewModel(tab);
        });
      };

      _Class.prototype.formatNewModel = function(model, collection, options) {
        model.set("view", "tabItem");
        return this.$el.children(".placeholder-text").hide();
      };

      return _Class;

    })(window.views["layout"]);
    return views["ListLayout"] = (function(_super) {
      __extends(_Class, _super);

      function _Class() {
        _ref8 = _Class.__super__.constructor.apply(this, arguments);
        return _ref8;
      }

      _Class.prototype.initialize = function() {
        _Class.__super__.initialize.apply(this, arguments);
        this.model.set("type", "List Layout");
        return _.bindAll(this, "afterRender");
      };

      _Class.prototype.afterRender = function() {
        return this.$el.addClass("list-layout");
      };

      return _Class;

    })(views['layout']);
  });

}).call(this);

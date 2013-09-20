// Generated by CoffeeScript 1.6.3
(function() {
  var __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  $(document).ready(function() {
    /* 
        MUST be bound to the window, so as not to leak into 
        global namespace and still have access to other scripts
    */

    var _ref, _ref1, _ref2;
    window.copiedModel = null;
    window.models.Element = (function(_super) {
      __extends(Element, _super);

      function Element() {
        _ref = Element.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Element.prototype.initialize = function() {
        var self;
        self = this;
        return this.on({
          "change:view": function(model, view, opts) {
            var collection, index;
            collection = model.collection;
            index = collection.indexOf(model);
            console.log(collection);
            if ((collection != null) && typeof collection !== "undefined") {
              collection.remove(model, {
                no_history: true
              });
              return collection.add(model, {
                at: index,
                no_history: true
              });
            }
          }
        });
      };

      Element.prototype.defaults = function() {
        var child_els;
        child_els = new collections.Elements();
        child_els.model = this;
        return {
          "child_els": child_els,
          "inFlow": true,
          classes: [],
          styles: {
            background: null,
            border: {
              left: {},
              right: {},
              top: {},
              bottom: {}
            },
            'box-shadow': null,
            color: null,
            font: {
              size: null,
              weight: null
            },
            opacity: null
          },
          title: "Default Title",
          editable: true
        };
      };

      Element.prototype.url = function() {
        var url;
        url = "/section/";
        url += this.id != null ? this.id : "";
        return url;
      };

      Element.prototype.modelify = function(basicObj) {
        var el;
        el = new models.Element(basicObj);
        return el.deepCopy();
      };

      Element.prototype.parse = function(response) {
        var section, self;
        self = this;
        section = [];
        _.each(response.currentSection, function(element) {
          return section.push(self.modelify(element));
        });
        return response;
      };

      Element.prototype.blend = function(putIn, opts) {
        var children, defaults, hide, options;
        if (putIn == null) {
          return false;
        }
        defaults = {
          opname: "change",
          at: 0
        };
        options = _.extend(defaults, opts || {});
        console.log(options);
        children = this.get("child_els");
        hide = {
          no_history: true
        };
        if ($.isArray(putIn) === true && putIn.length > 1) {
          options.opname += " " + putIn.length + " ";
          if (putIn.indexOf(this) !== -1) {
            alert("you may not drag shit into itself. DIVIDE BY ZERO");
            return false;
          }
          _.each(putIn, function(model, i) {
            if (model.collection != null) {
              model.collection.remove(model, hide);
            }
            options.no_history = true;
            if (i < putIn.length - 1) {
              return children.add(model, options);
            } else {
              options.no_history = false;
              return children.add(model, options);
            }
          });
          return;
        } else if (putIn.collection != null) {
          putIn.collection.remove(putIn, hide);
        }
        children.add(putIn, options);
        return true;
      };

      Element.prototype.deepCopy = function() {
        var children, clone, model, self;
        model = this;
        clone = model.clone();
        if (clone.get("child_els").models != null) {
          children = clone.get("child_els").clone();
        } else {
          children = new collections.Elements(clone.get("child_els")).clone();
        }
        self = this;
        _.each(children.models, function(child) {
          return child = child.deepCopy();
        });
        clone.set("child_els", children);
        return clone;
      };

      return Element;

    })(Backbone.Model);
    window.collections.Elements = Backbone.Collection.extend({
      model: models.Element,
      url: '/section/',
      reorder: function(newIndex, originalIndex, collection, options) {
        var op, temp;
        if ((options != null) && (options.opname != null)) {
          op = options.opname;
        }
        if (newIndex === originalIndex) {
          return this;
        }
        collection = collection || this;
        temp = collection.at(originalIndex);
        collection.remove(temp, {
          organizer: {
            itemRender: false,
            render: false
          },
          no_history: true
        });
        collection.add(temp, {
          at: newIndex,
          organizer: {
            itemRender: false,
            render: false
          },
          opname: op
        });
        return this;
      },
      gather: function(prop) {
        var models, self;
        prop = prop || "selected";
        models = [];
        self = this;
        _.each(this.models, function(model) {
          if (model[prop] === true) {
            models.push(model);
          }
          return models = models.concat(model.get("child_els").gather());
        });
        return models;
      },
      clone: function() {
        var copy;
        copy = new collections.Elements();
        _.each(this.models, function(element) {
          return copy.add(element.deepCopy(), {
            no_history: true
          });
        });
        return copy;
      },
      compare: function(collection) {
        return _.isEqual(this.models, collection.models);
      }
    });
    window.views.droppablePlaceholder = (function(_super) {
      __extends(droppablePlaceholder, _super);

      function droppablePlaceholder() {
        _ref1 = droppablePlaceholder.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      droppablePlaceholder.prototype.contextMenu = $("#placeholder-context").html();

      droppablePlaceholder.prototype.tagName = 'div';

      droppablePlaceholder.prototype.className = 'droppable-placeholder';

      droppablePlaceholder.prototype.events = {
        "click .paste-element": function(e) {
          var clone, dropZone, insertAt, models;
          clone = window.copiedModel;
          dropZone = this.$el;
          insertAt = dropZone.siblings(".builder-element").index(dropZone.prev()) + 1;
          if ((this.collection != null) && (clone != null)) {
            this.collection.add(clone, {
              at: insertAt,
              opname: 'Paste'
            });
            if ($.isArray(clone)) {
              models = [];
              _.each(clone, function(model) {
                return models.push(model.deepCopy());
              });
              window.copiedModel = models;
            } else {
              window.copiedModel = clone.deepCopy();
            }
          }
          return e.stopPropagation();
        },
        "remove": "remove",
        "contextmenu": function(e) {
          var $el, pageX, pageY;
          e.stopPropagation();
          if (window.copiedModel === null) {
            return true;
          }
          $(".context-menu").remove();
          e.preventDefault();
          $el = this.$el;
          pageX = e.pageX - $el.offset().left;
          pageY = e.pageY - $el.offset().top;
          $("<ul />").html(_.template(this.contextMenu, {})).addClass("context-menu").css({
            "top": pageY + "px",
            "left": pageX + "px"
          }).appendTo(this.$el);
          return false;
        }
      };

      droppablePlaceholder.prototype.render = function() {
        var self;
        self = this;
        return this.$el.droppable({
          accept: ".builder-element, .outside-draggables li, .property",
          greedy: true,
          tolerance: 'pointer',
          over: function(e, ui) {
            if ($(document.body).hasClass("active-modal")) {
              return false;
            }
            return $(e.target).addClass("show");
          },
          out: function(e, ui) {
            return $(e.target).removeClass("show").find("ul").remove();
          },
          drop: function(e, ui) {
            var curr, dropZone, insertAt, parent;
            $(e.target).removeClass("show");
            $(".over").removeClass("over");
            if ($(document.body).hasClass("active-modal")) {
              return false;
            }
            dropZone = $(e.target);
            insertAt = dropZone.siblings(".builder-element").index(dropZone.prev()) + 1;
            curr = window.currentDraggingModel;
            if (!$.isArray(curr) && curr.get("inFlow") === false) {
              cc("drop inflowing");
              curr.set("inFlow", true);
              return;
            }
            parent = self.collection.model;
            if (typeof parent === "function" || (parent == null)) {
              parent = self.collection;
            }
            parent.blend(curr, {
              at: insertAt
            });
            delete window.currentDraggingModel;
            window.currentDraggingModel = null;
            return ui.helper.fadeOut(300);
          }
        });
      };

      return droppablePlaceholder;

    })(Backbone.View);
    /* A configurable element bound to a property or page element
        Draggable, droppable, nestable.
    */

    window.views.draggableElement = (function(_super) {
      __extends(draggableElement, _super);

      function draggableElement() {
        _ref2 = draggableElement.__super__.constructor.apply(this, arguments);
        return _ref2;
      }

      draggableElement.prototype.template = $("#draggable-element").html();

      draggableElement.prototype.controls = $("#drag-controls").html();

      draggableElement.prototype.contextMenu = $("#context-menu-default").html();

      draggableElement.prototype.tagName = 'div';

      draggableElement.prototype.className = 'builder-element';

      draggableElement.prototype.modelListeners = {};

      draggableElement.prototype.initialize = function() {
        _.bindAll(this, "render", "bindDrag", "bindListeners", "bindResize");
        this.on("bindListeners", this.bindListeners);
        this.bindDrag();
        return this.bindListeners();
      };

      draggableElement.prototype.bindResize = function() {
        var grid_block, parent, parent_width;
        parent = this.options.parent;
        parent_width = parent.width();
        grid_block = parent_width / 6;
        return this.$el.resizable({
          handles: "e",
          containment: 'parent',
          grid: grid_block,
          autoHide: true,
          resize: function(e, ui) {
            parent_width = parent.width();
            grid_block = parent_width / 6;
            $(this).resizable("option", "grid", grid_block);
            return ui.helper.css({
              "position": "relative",
              "top": "",
              "left": ""
            });
          },
          start: function(e, ui) {
            return ui.helper.css({
              "position": "relative",
              "top": "",
              "left": ""
            });
          }
        });
      };

      draggableElement.prototype.bindListeners = function() {
        var self;
        self = this;
        this.stopListening();
        this.listenTo(this.model.get("child_els"), {
          'add': function(m, c, o) {
            if (!(typeof self.itemName === "undefined")) {
              m.set("view", self.itemName);
            }
            return self.appendChild(m, o);
          },
          'reset': this.render
        });
        this.modelListeners = _.extend({}, this.modelListeners, {
          "change:classes": function() {
            return this.render(false);
          },
          "change:child_els": function() {
            self.bindListeners();
            return self.render();
          },
          "change:inFlow": function(model) {
            if (model.get("inFlow") === true) {
              return self.$el.slideDown("fast").next(".droppable-placeholder").slideDown("fast").prev(".droppable-placeholder").slideDown("fast");
            } else {
              self.$el.slideUp("fast").next(".droppable-placeholder").hide();
              return self.$el.prev(".droppable-placeholder").hide();
            }
          },
          "remove": function() {
            self.$el.next(".droppable-placeholder").remove();
            return self.remove();
          },
          "link-feedback": function() {
            return self.$el.addClass("link-feedback");
          },
          "end-feedback": function() {
            return self.$el.removeClass("link-feedback");
          },
          "renderBase": function() {
            return self.render(false);
          },
          "render": function() {
            return self.render(true);
          },
          "showConfigModal": this.showConfigModal
        });
        return this.listenTo(this.model, this.modelListeners);
      };

      draggableElement.prototype.render = function(do_children) {
        var $el, children, model, that;
        if (typeof do_children === "undefined") {
          do_children = true;
        }
        (this.beforeRender || function() {
          return {};
        })();
        that = this;
        model = this.model;
        model["selected"] = false;
        children = model.get("child_els");
        $el = this.$el;
        $el.html(_.template(this.template, model.toJSON()));
        if (this.controls != null) {
          $el.append(_.template(this.controls, model.toJSON()));
        }
        if ($el.children(".children").length === 0) {
          $el.append($("<ul/>").addClass("children"));
        }
        if ((children != null) && do_children === true) {
          if (children.length > 0) {
            this.$el.children(".placeholder").hide();
          }
          _.each(children.models, function(el) {
            return that.appendChild(el, {});
          });
        }
        this.applyClasses();
        this.checkPlaceholder();
        this.$(".view-attrs").first().trigger("click");
        (this.afterRender || function() {})();
        return this;
      };

      draggableElement.prototype.bindDrag = function() {
        var that;
        that = this;
        return this.$el.draggable({
          cancel: ".no-drag, .context-menu, .ui-resizable-handle",
          revert: true,
          scrollSensitivity: 100,
          helper: function() {
            var selected, self, wrap;
            selected = that.$el.closest("section").find(".ui-selected, .selected-element");
            self = $(this);
            if (!self.hasClass("selected-element")) {
              return self;
            }
            console.log("helper");
            wrap = $("<div />").html(self.clone()).css("width", "100%");
            selected.each(function() {
              console.log("eachin");
              if (!self.is(this)) {
                if ($(this).index() > self.index()) {
                  return wrap.append($(this).clone());
                } else {
                  return wrap.prepend($(this).clone());
                }
              }
            });
            return wrap.addClass("selected-element");
          },
          cursor: "move",
          start: function(e, ui) {
            var allDraggingModels, sect_interface, section;
            if (e.shiftKey === true) {
              return false;
            }
            sect_interface = allSections.at(currIndex);
            section = sect_interface.get("currentSection");
            ui.helper.addClass("dragging");
            if (ui.helper.hasClass("selected-element")) {
              allDraggingModels = section.gather();
            } else {
              allDraggingModels = [];
            }
            console.log(allDraggingModels.length);
            if (allDraggingModels.length > 1) {
              return window.currentDraggingModel = allDraggingModels;
            } else {
              return window.currentDraggingModel = that.model;
            }
          },
          stop: function(e, ui) {
            return $(ui.helper).removeClass("dragging");
          }
        });
      };

      draggableElement.prototype.removeFromFlow = function(e) {
        var destroy, that;
        that = this;
        destroy = function() {
          return that.model.set("inFlow", false, {
            opname: "Flow Out"
          });
        };
        if (e.type === "flowRemoveViaDrag") {
          this.$el.toggle("clip", 300, destroy);
        } else {
          destroy();
        }
        e.stopPropagation();
        return e.stopImmediatePropagation();
      };

      draggableElement.prototype.checkPlaceholder = function() {};

      draggableElement.prototype.applyClasses = function() {
        var $el;
        $el = this.$el;
        return _.each(this.model.get("classes"), function(style) {
          return $el.addClass(style);
        });
      };

      draggableElement.prototype.blankLayout = function(e) {
        var collection, layout, layoutIndex, selected;
        cc(currIndex);
        collection = allSections.at(window.currIndex).get("currentSection");
        selected = collection.gather();
        if (selected.length === 0 || selected.length === 1) {
          return;
        }
        layoutIndex = collection.indexOf(selected[0]);
        collection.add(layout = new models.Element({
          view: 'DynamicLayout',
          type: 'Dynamic Layout'
        }), {
          at: layoutIndex,
          no_history: true
        });
        _.each(selected, function(model) {
          if (model.collection != null) {
            model.collection.remove(model, {
              no_history: true
            });
          }
          return layout.get("child_els").add(model);
        });
        if (e != null) {
          e.stopPropagation();
        }
        return this;
      };

      draggableElement.prototype.exportAsSection = function() {
        var copy, title, wrapper;
        title = this.model.get("title");
        if (title === "" || typeof title === "undefined" || title === "Default Section Title") {
          alert("You need to enter a title");
          return false;
        }
        copy = new models.SectionController();
        wrapper = new collections.Elements();
        wrapper.add(this.model);
        copy.set({
          currentSection: wrapper,
          section_title: title
        });
        copy.save(null, {
          success: function() {
            $("<div />").addClass("modal center").html("You saved the section").appendTo(document.body);
            $(document.body).addClass("active-modal");
            return $(".modal").delay(2000).fadeOut("fast", function() {
              $(this).remove();
              return $(document.body).removeClass("active-modal");
            });
          }
        });
        return true;
      };

      draggableElement.prototype.bindContextMenu = function(e) {
        var $el, item, pageX, pageY;
        if (this.contextMenu == null) {
          return true;
        } else if (e.shiftKey === true) {
          this.unbindContextMenu(e);
          return true;
        }
        this.unbindContextMenu(e);
        e.preventDefault();
        $el = this.$el;
        pageX = e.pageX - $el.offset().left;
        pageY = e.pageY - $el.offset().top;
        item = this.model.toJSON();
        item.selected = false;
        if (this.model["selected"] === true) {
          item.selected = true;
        }
        $("<ul />").html(_.template(this.contextMenu, item)).addClass("context-menu").css({
          "top": pageY + "px",
          "left": pageX + "px"
        }).appendTo(this.$el);
        e.stopPropagation();
        return false;
      };

      draggableElement.prototype.unbindContextMenu = function(e) {
        var menu;
        cc("unbinding");
        menu = $(".context-menu");
        if ((e != null) && $(e.currentTarget).hasClass("context-menu")) {
          return false;
        }
        return menu.remove();
      };

      draggableElement.prototype.showConfigModal = function(e) {
        var defaultEditor, editor;
        defaultEditor = this.model.get("layout") === true ? "BaseLayoutEditor" : "BaseEditor";
        editor = views.editors[this.edit_view || this.model.get("view") || defaultEditor];
        if (editor != null) {
          editor = new editor({
            model: this.model,
            link_el: this.el
          }).render();
        } else {
          editor = new views.editors[defaultEditor]({
            model: this.model,
            link_el: this.el
          }).render();
        }
        return $(editor.el).launchModal();
      };

      draggableElement.prototype.selectEl = function() {
        var layout;
        layout = this.model["selected"];
        if (layout === false || typeof layout === "undefined") {
          return this.$el.trigger("select");
        } else {
          return this.$el.trigger("deselect");
        }
      };

      draggableElement.prototype.events = {
        "click .context-menu > li.copy-element": function() {
          var copy;
          copy = this.model.deepCopy();
          return window.copiedModel = copy;
        },
        "click .context-menu > li.cut-element": function() {
          var copy;
          copy = this.model.deepCopy();
          window.copiedModel = copy;
          return this.model.collection.remove(this.model, {
            opname: 'Cut'
          });
        },
        "click .context-menu > li.select-this": function() {
          return this.selectEl();
        },
        "click .group-elements": "blankLayout",
        "click .destroy-element": function() {
          return this.model.destroy();
        },
        "click .context-menu li": function(e) {
          var $t;
          $t = $(e.currentTarget);
          if (!$t.hasClass("disabled")) {
            return this.unbindContextMenu();
          }
        },
        "dblclick": function(e) {
          console.log(this.model.toJSON());
          this.showConfigModal();
          return e.stopPropagation();
        },
        "click": function(e) {
          this.unbindContextMenu(e);
          this.$el.find(".dropdown").hide();
          if (e.shiftKey === true || e.ctrlKey === true) {
            this.selectEl();
          }
          e.preventDefault();
          e.stopPropagation();
          return false;
        },
        "contextmenu": "bindContextMenu",
        "click .export": "exportAsSection",
        "click .set-options": function(e) {
          var $t, dropdown;
          this.unbindContextMenu(e);
          $t = $(e.currentTarget);
          dropdown = $t.children(".dropdown");
          $(".dropdown").not(dropdown).hide();
          dropdown.fadeToggle(100);
          return e.stopPropagation();
        },
        "click .set-options li": function(e) {
          this.unbindContextMenu(e);
          e.preventDefault();
          return e.stopPropagation();
        },
        "click .view-attrs": function(e) {
          var button, props;
          props = new views.toolbelt.Actives({
            model: this.model
          }).render().el;
          $(".quick-props").find("ul").html(props);
          if ((e != null) && e.isTrigger === true) {
            return;
          }
          button = $(".quick-props").find(".close-arrow");
          return button.trigger("click");
        },
        "click .remove-from-flow": function(e) {
          e.stopPropagation();
          return this.removeFromFlow(e);
        },
        "flowRemoveViaDrag": "removeFromFlow",
        "click .config-panel": "showConfigModal",
        "select": function(e) {
          this.model["selected"] = true;
          this.$el.addClass("selected-element");
          e.stopPropagation();
          return e.stopImmediatePropagation();
        },
        "deselect": function(e) {
          this.model["selected"] = false;
          this.$el.removeClass("selected-element");
          e.stopPropagation();
          return e.stopImmediatePropagation();
        },
        "sorting": function() {
          return this.$el.addClass("active-sorting");
        },
        "end-sorting": function() {
          return this.$el.removeClass("active-sorting");
        },
        "mouseleave": function() {
          return this.$(".set-options > ul").hide();
        },
        "mouseover .config-menu-wrap > li": function(e) {
          var $t, self;
          $t = $(e.currentTarget);
          $t.data("over", true);
          self = $t;
          window.setTimeout(function() {
            if ($t.data("over") === true) {
              return self.showTooltip();
            }
          }, 500);
          return e.stopPropagation();
        },
        "mouseleave .config-menu-wrap > li": function(e) {
          var $t;
          $t = $(e.currentTarget);
          $t.data("over", false);
          $t.hideTooltip();
          return e.stopPropagation();
        }
      };

      return draggableElement;

    })(Backbone.View);
    return window.views.SectionBuilder = Backbone.View.extend({
      rendered: false,
      initialize: function() {
        this.controller = this.options.controller;
        this.wrapper = $(".control-section").eq(this.controller.index);
        this.$el = this.wrapper.find("section");
        this.collection = this.options.collection;
        return this.render();
      },
      render: function(children) {
        var $el, that;
        if (this.rendered !== true) {
          this.rendered = true;
          $el = this.$el;
          that = this;
          return this.append(this.scaffold = new models.Element({
            view: "BuilderWrapper"
          }));
        }
      },
      append: function(element, opts) {
        var draggable, view;
        view = element.get("view");
        element.set("child_els", this.collection);
        this.$el.append(draggable = $(new views[view]({
          model: element,
          parent: this.$el
        }).render().el));
        this.removeExtraPlaceholders();
        return draggable;
      },
      removeExtraPlaceholders: function() {
        return this.$el.find(".droppable-placeholder").each(function() {
          var $t, flag;
          $t = $(this);
          flag = 0;
          if ($t.next().hasClass("droppable-placeholder")) {
            $t.next().remove();
          }
          if ($t.prev().hasClass("droppable-placeholder")) {
            $t.prev().remove();
          }
          if (!$t.next().hasClass("builder-element")) {
            flag += 1;
          }
          if (!$t.prev().hasClass("builder-element")) {
            flag += 1;
          }
          if (flag === 2) {
            return $t.remove();
          }
        });
      }
    });
  });

}).call(this);

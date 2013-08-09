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
    window.globals = {
      setPlaceholders: function(draggable, collection) {
        var after, before;
        draggable.before(before = new views.droppablePlaceholder({
          collection: collection
        }).render()).after(after = new views.droppablePlaceholder({
          collection: collection
        }).render());
        if (before.prev().css("display") === "inline-block") {
          return before.css("height", before.prev().height() + "px");
        }
      }
    };
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
          }
        };
      };

      Element.prototype.url = function() {
        var url;
        url = "/section/";
        url += this.id != null ? this.id : "";
        return url;
      };

      Element.prototype.modelify = function() {
        var clone, self, temp;
        self = this;
        temp = new collections.Elements();
        if (this.get("child_els") == null) {
          return false;
        }
        return clone = this.get("child_els").clone();
      };

      Element.prototype.parse = function(response) {
        response.child_els = this.modelify(response.child_els);
        return response;
      };

      Element.prototype.blend = function(putIn, at) {
        var children;
        if (putIn == null) {
          return false;
        }
        if ($.isArray(putIn) === true && putIn.length > 1) {
          if (putIn.indexOf(this) !== -1) {
            alert("you may not drag shit into itself. DIVIDE BY ZERO");
            return false;
          }
          _.each(putIn, function(model) {
            return model.collection.remove(model, {
              no_history: true
            });
          });
        } else if (putIn.collection != null) {
          putIn.collection.remove(putIn, {
            no_history: true
          });
        }
        children = this.get("child_els");
        children.add(putIn, {
          at: at,
          opname: 'Switch'
        });
        this.set("child_els", children);
        return true;
      };

      return Element;

    })(Backbone.Model);
    window.collections.Elements = Backbone.Collection.extend({
      model: models.Element,
      url: '/section/',
      blend: function(putIn, at) {
        if (putIn == null) {
          return false;
        }
        if ($.isArray(putIn) === true && putIn.length > 1) {
          _.each(putIn, function(model) {
            return model.collection.remove(model, {
              no_history: true
            });
          });
        } else if (putIn.collection != null) {
          putIn.collection.remove(putIn, {
            no_history: true
          });
        }
        this.add(putIn, {
          at: at,
          opname: "Switch"
        });
        return true;
      },
      reorder: function(newIndex, originalIndex, collection, options) {
        var temp;
        if (newIndex === originalIndex) {
          return this;
        }
        collection = collection || this;
        temp = collection.at(originalIndex);
        collection.remove(temp, {
          organizer: {
            itemRender: false
          },
          no_history: true
        });
        collection.add(temp, {
          at: newIndex,
          organizer: {
            itemRender: false,
            render: false
          },
          opname: 'Switch'
        });
        return this;
      },
      gather: function(prop) {
        var models, self;
        prop = prop || "layout-item";
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
          var children, deep_copy_model;
          deep_copy_model = element.clone();
          children = deep_copy_model.get("child_els");
          deep_copy_model.set("child_els", children.clone(), {
            no_history: true
          });
          return copy.add(new models.Element(deep_copy_model.toJSON()), {
            no_history: true
          });
        });
        return copy;
      }
    });
    window.views.droppablePlaceholder = (function(_super) {
      __extends(droppablePlaceholder, _super);

      function droppablePlaceholder() {
        _ref1 = droppablePlaceholder.__super__.constructor.apply(this, arguments);
        return _ref1;
      }

      droppablePlaceholder.prototype.events = {
        "remove": function() {
          return this.remove();
        }
      };

      droppablePlaceholder.prototype.render = function() {
        var ghostFragment, self;
        self = this;
        ghostFragment = $("<div/>").addClass("droppable-placeholder").html("<div class='make-bigger'></div>");
        return ghostFragment.droppable({
          accept: ".builder-element, .outside-draggables li, .property",
          greedy: true,
          tolerance: 'pointer',
          over: function(e, ui) {
            if ($(document.body).hasClass("active-modal")) {
              return false;
            }
            return $(e.target).css("opacity", 1);
          },
          out: function(e, ui) {
            return $(e.target).css("opacity", 0);
          },
          drop: function(e, ui) {
            var curr, dropZone, insertAt, parent;
            $(".over").removeClass("over");
            if ($(document.body).hasClass("active-modal")) {
              return false;
            }
            dropZone = $(e.target);
            if ((dropZone.closest(".builder-element").length)) {
              insertAt = dropZone.closest(".builder-element").children(".children").children(".builder-element").index(dropZone.prev());
            } else {
              insertAt = dropZone.closest("section").children(".children").children(".builder-element").index(dropZone.prev());
            }
            insertAt += 1;
            curr = window.currentDraggingModel;
            parent = self.collection.model;
            if (typeof parent === "function" || (parent == null)) {
              parent = self.collection;
            }
            parent.blend(curr, insertAt);
            $(e.target).css("opacity", 0);
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

      draggableElement.prototype.tagName = 'div class="builder-element"';

      draggableElement.prototype.modelListeners = {};

      draggableElement.prototype.initialize = function() {
        _.bindAll(this, "render", "bindDrop", "bindDrag", "appendChild", "bindListeners");
        this.on("bindListeners", this.bindListeners);
        this.bindDrop();
        this.bindDrag();
        return this.bindListeners();
      };

      draggableElement.prototype.bindListeners = function() {
        var self;
        self = this;
        this.stopListening();
        this.listenTo(this.model.get("child_els"), {
          'add': function(m, c, o) {
            if (!(typeof self.itemName === "undefined")) {
              console.log(self.itemName);
              m.set("view", self.itemName);
            }
            return self.appendChild(m, o);
          }
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
              return self.$el.slideUp("fast").next(".droppable-placeholder").slideUp("fast").prev(".droppable-placeholder").slideUp("fast");
            }
          },
          "remove": function() {
            self.$el.next(".droppable-placeholder").remove();
            return self.remove();
          },
          "sorting": function() {
            return self.$el.addClass("selected-element");
          },
          "end-sorting": function() {
            if (self.$el.hasClass("ui-selected") === false) {
              return self.$el.removeClass("selected-element");
            }
          },
          "renderBase": function() {
            return self.render(false);
          },
          "render": function() {
            return self.render(true);
          }
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
        model["layout-item"] = false;
        children = model.get("child_els");
        $el = this.$el;
        $el.html(_.template(this.template, model.toJSON()));
        if (this.controls != null) {
          $el.append(_.template(this.controls, model.toJSON()));
        }
        if ($el.children(".children").length === 0) {
          $el.append("<ul class='children'></ul>");
        }
        if ((children != null) && do_children === true) {
          _.each(children.models, function(el) {
            return that.appendChild(el, {});
          });
        }
        this.applyClasses();
        this.checkPlaceholder();
        (this.afterRender || function() {
          return $el.hide().fadeIn(325);
        })();
        return this;
      };

      draggableElement.prototype.appendChild = function(child, opts) {
        var $el, builderChildren, draggable, i, view;
        console.log("appending child!");
        $el = this.$el.children(".children");
        if ($el.length === 0) {
          $el = $el.find(".children").first();
        }
        if (child['layout-element'] === true) {
          $el.addClass("selected-element");
        }
        view = child.get("view") || "draggableElement";
        if (child.get("inFlow") === true) {
          i = currIndex;
          draggable = $(new views[view]({
            model: child,
            index: i
          }).render().el).addClass("builder-child");
          if ((opts != null) && (opts.at == null)) {
            $el.append(draggable);
          } else {
            console.log(opts.at);
            builderChildren = $el.children(".builder-element");
            if (builderChildren.eq(opts.at).length) {
              builderChildren.eq(opts.at).before(draggable);
            } else {
              $el.append(draggable);
            }
          }
          globals.setPlaceholders($(draggable), this.model.get("child_els"));
          return allSections.at(currIndex).get("builder").removeExtraPlaceholders();
        }
      };

      draggableElement.prototype.bindDrag = function() {
        var that;
        that = this;
        return this.$el.draggable({
          cancel: ".no-drag, .context-menu",
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

      draggableElement.prototype.bindDrop = function() {
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

      draggableElement.prototype.removeFromFlow = function(e) {
        var destroy, that;
        that = this;
        destroy = function() {
          return that.model.set("inFlow", false);
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
        console.log(this.model.get("classes"));
        return _.each(this.model.get("classes"), function(style) {
          return $el.addClass(style);
        });
      };

      draggableElement.prototype.blankLayout = function(e) {
        var collection, layout, layoutIndex, selected;
        collection = allSections.at(currIndex).get("currentSection");
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
        _.each(selected, function(model) {
          if (model.collection != null) {
            model.collection.remove(model, {
              no_history: true
            });
          }
          return layout.get("child_els").add(model);
        });
        return this;
      };

      draggableElement.prototype.bindContextMenu = function(e) {
        var $el, pageX, pageY;
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
        $("<ul />").html(_.template(this.contextMenu, {})).addClass("context-menu").css({
          "top": pageY + "px",
          "left": pageX + "px"
        }).appendTo(this.$el);
        e.stopPropagation();
        return false;
      };

      draggableElement.prototype.unbindContextMenu = function(e) {
        var menu;
        menu = $(".context-menu");
        if ((e != null) && $(e.currentTarget).hasClass("context-menu")) {
          return false;
        } else if (!menu.length) {
          return false;
        }
        return menu.remove();
      };

      draggableElement.prototype.events = {
        "dblclick": function(e) {
          console.log(this.model);
          return e.stopPropagation();
        },
        "contextmenu": "bindContextMenu",
        "click .context-menu": function(e) {
          return e.stopPropagation();
        },
        "click .group-elements": "blankLayout",
        "click .destroy-element": function() {
          return this.model.destroy();
        },
        "click": function(e) {
          var layout;
          this.unbindContextMenu(e);
          this.$el.find(".dropdown").hide();
          if (e.shiftKey === true) {
            layout = this.model["layout-item"];
            if (layout === false || typeof layout === "undefined") {
              this.$el.trigger("select");
            } else {
              this.$el.trigger("deselect");
            }
          }
          e.stopPropagation();
          return e.stopImmediatePropagation();
        },
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
        "click .view-attrs": function() {
          return new views.toolbelt.Actives({
            model: this.model
          }).render();
        },
        "click .remove-from-flow": function(e) {
          e.stopPropagation();
          return this.removeFromFlow(e);
        },
        "flowRemoveViaDrag": "removeFromFlow",
        "click .config-panel": function(e) {
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
        },
        "select": function(e) {
          this.model["layout-item"] = true;
          this.$el.addClass("selected-element");
          e.stopPropagation();
          return e.stopImmediatePropagation();
        },
        "deselect": function(e) {
          this.model["layout-item"] = false;
          this.$el.removeClass("selected-element");
          e.stopPropagation();
          return e.stopImmediatePropagation();
        },
        "sorting": function() {
          return this.$el.addClass("active-sorting");
        },
        "end-sorting": function() {
          return this.$el.removeClass("active-sorting");
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
          model: element
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

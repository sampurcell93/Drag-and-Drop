// Generated by CoffeeScript 1.6.3
(function() {
  $(document).ready(function() {
    /* 
        MUST be bound to the window, so as not to leak into 
        global namespace and still have access to other scripts
    */

    window.models = {};
    window.views = {};
    window.collections = {};
    window.models.Element = Backbone.Model.extend({
      defaults: function() {
        return {
          "child_els": new collections.Elements(),
          "inFlow": true
        };
      },
      url: function() {
        var url;
        url = "/section/";
        url += this.id != null ? this.id : "";
        return url;
      },
      modelify: function(child_els) {
        var self, temp;
        self = this;
        temp = new collections.Elements();
        _.each(child_els, function(model) {
          var tempModel;
          temp.add(tempModel = new models.Element(model));
          return tempModel.set("child_els", self.modelify(tempModel.get("child_els")));
        });
        return temp;
      },
      parse: function(response) {
        var self;
        self = this;
        response.child_els = this.modelify(response.child_els);
        return response;
      }
    });
    window.collections.Elements = Backbone.Collection.extend({
      model: models.Element,
      url: '/section/',
      blendModels: function(addTo, putIn) {
        var children;
        if (putIn.collection != null) {
          putIn.collection.remove(putIn);
        }
        children = addTo.get("child_els");
        if (children != null) {
          addTo.set("child_els", children.add(putIn));
          return organizer.render();
        }
      }
    });
    window.views.ElementOrganizer = Backbone.View.extend({
      el: '#organize-elements',
      initialize: function() {
        /* Render the list, then apply the drag and drop, and sortable functions.*/

        var that;
        _.bindAll(this, "reorderCollection", "render");
        this.collection.on("change", this.render, this);
        this.collection.on("add", this.render, this);
        this.render();
        that = this;
        return this.$el.sortable({
          axis: 'y',
          tolerance: 'touch',
          connectWith: 'ul',
          containment: 'parent',
          handle: '.sort-element',
          items: 'li',
          start: function(e, ui) {
            return that.origIndex = $(ui.item).addClass("moving-sort").index();
          },
          stop: function(e, ui) {
            return that.reorderCollection($(ui.item).removeClass("moving-sort").index(), that.origIndex);
          }
        });
      },
      render: function() {
        var $el, outOfFlow, that;
        $el = this.$el;
        $el.empty();
        that = this;
        outOfFlow = [];
        _.each(this.collection.models, function(el) {
          var itemView;
          if (el.get("inFlow") === false) {
            outOfFlow.push(el);
            return;
          }
          itemView = new views.SortableElementItem({
            model: el
          });
          return $el.append(itemView.render().el);
        });
        return _.each(outOfFlow, function(out, i) {
          var itemView;
          itemView = new views.SortableElementItem({
            model: out,
            outOfFlow: true
          });
          return $el.append(itemView.render().el);
        });
      },
      reorderCollection: function(newIndex, originalIndex, collection) {
        var temp;
        collection = collection || this.collection;
        temp = collection.at(originalIndex);
        collection.remove(temp, {
          silent: true
        });
        collection.add(temp, {
          at: newIndex,
          silent: true
        });
        return builder.render();
      }
    });
    window.views.SortableElementItem = Backbone.View.extend({
      tagName: 'li class="property"',
      template: $("#element-sortable-item").html(),
      initialize: function() {
        var that;
        that = this;
        this.listenTo(this.model, 'change', this.render);
        this.listenTo(this.model.get("child_els"), 'change', this.render);
        return this.$el.draggable({
          cancel: ".sort-element, .destroy-element, .activate-element",
          revert: "invalid",
          helper: "clone",
          cursor: "move",
          cursorAt: {
            top: 50
          },
          start: function() {
            if (typeof builder !== "undefined" && builder !== null) {
              builder.currentModel = that.model;
              return builder.fromSideBar = true;
            }
          }
        });
      },
      render: function() {
        var $el, childList, that;
        $el = this.$el;
        $el.html(_.template(this.template, this.model.toJSON()));
        childList = $el.children(".child-list");
        that = this;
        this.outOfFlow = [];
        _.each(this.model.get("child_els").models, function(el) {
          if (el.get("inFlow") === true) {
            return childList.append(new views.SortableElementItem({
              model: el,
              child: true
            }).render().el);
          } else {
            return childList.append(new views.SortableElementItem({
              model: el,
              child: true,
              outOfFlow: true
            }).render().el);
          }
        });
        if (this.options.outOfFlow === true) {
          $el.addClass("out-of-flow");
          $("<div />").addClass("activate-element").text("m").prependTo($el);
          $("<div />").addClass("destroy-element").text("g").prependTo($el);
        }
        if (childList.children().length > 1) {
          childList.sortable({
            items: 'li',
            axis: 'y',
            containment: 'parent',
            start: function(e, ui) {
              return that.origIndex = $(ui.item).index();
            },
            stop: function(e, ui) {
              return organizer.reorderCollection($(ui.item).index(), that.origIndex, that.model.get("child_els"));
            }
          });
        }
        return this;
      },
      events: {
        "click .sort-element": function(e) {
          console.log($(e.target));
          return e.stopImmediatePropagation();
        },
        "click .activate-element": function() {
          return this.model.set("inFlow", true);
        },
        "click .destroy-element": function() {
          this.model.destroy();
          return this.remove();
        }
      }
    });
    /* A configurable element bound to a property or page element
        Draggable, droppable, nestable.
    */

    window.views.draggableElement = Backbone.View.extend({
      template: $("#draggable-element").html(),
      controls: $("#drag-controls").html(),
      tagName: 'div class="builder-element"',
      initialize: function() {
        _.bindAll(this, "render", "bindDrop", "bindDrag", "distance", "setStyles");
        this.listenTo(this.model, 'change', this.render);
        return this.listenTo(this.model.get("child_els"), 'change', this.render);
      },
      render: function() {
        var $el, children, model, template, that;
        that = this;
        model = this.model;
        children = model.get("child_els");
        $el = this.$el;
        this.setStyles();
        template = $(model.get("template")).html() || this.template;
        console.log(template, model.get("template"));
        $el.html(_.template(template, model.toJSON())).append(_.template(this.controls, {
          title: 'yo'
        }));
        if (children != null) {
          _.each(children.models, function(el) {
            var draggable;
            if (el.get("inFlow") === true) {
              draggable = new views.draggableElement({
                model: el
              }).render().el;
              return that.$el.append(draggable);
            }
          });
        }
        if ($el.prev(".builder-element").css("float") === "none") {
          $el.before($("<div />").addClass("clear"));
        }
        this.bindDrop();
        this.bindDrag();
        return this;
      },
      setStyles: function() {
        var styles;
        styles = this.model.get("styles");
        if (styles != null) {
          return this.$el.css(styles);
        }
      },
      bindDrag: function() {
        var cancel, that;
        that = this;
        cancel = ".config-menu-wrap, input, textarea";
        cancel += this.options.child != null ? "" : ", .child";
        return this.$el.draggable({
          cancel: cancel,
          revert: "invalid",
          cursor: "move",
          start: function(e, ui) {
            $(ui.helper).addClass("dragging");
            if (typeof builder !== "undefined" && builder !== null) {
              builder.currentModel = that.model;
              builder.fromSideBar = false;
              return console.log;
            }
          },
          stop: function(e, ui) {
            $(ui.helper).removeClass("dragging");
            if (ui.helper.data('dropped') === true) {
              return $(e.target).remove();
            }
          }
        });
      },
      distance: function(point1, point2) {
        var xs, ys;
        xs = 0;
        ys = 0;
        xs = point2.left - point1.left;
        xs = xs * xs;
        ys = point2.top - point1.top;
        ys = ys * ys;
        return Math.sqrt(xs + ys);
      },
      bindDrop: function() {
        var that;
        that = this;
        return this.$el.droppable({
          greedy: true,
          tolerance: 'pointer',
          accept: '*',
          over: function(e) {
            return $(e.target).addClass("over");
          },
          out: function(e) {
            return $(e.target).removeClass("over");
          },
          drop: function(e, ui) {
            /* Deals with the actual layout changes*/

            var curr, flow;
            $(e.target).removeClass("over");
            curr = builder.currentModel;
            flow = curr.get("inFlow");
            if ((flow === false || typeof flow === "undefined") || builder.fromSideBar === false) {
              curr.set("inFlow", true);
              $(ui.item).remove();
              ui.draggable.data('dropped', true);
              /* Now, we must consolidate models*/

              builder.collection.blendModels(that.model, curr);
              return that.render();
            } else {
              return alert("That item is already in the page flow.");
            }
          }
        });
      },
      events: {
        "click .set-options": function(e) {
          var $t, dropdown;
          console.log(this.model.get("type"));
          $t = $(e.currentTarget);
          dropdown = $t.children(".dropdown");
          dropdown.fadeToggle(100);
          return e.stopPropagation();
        },
        "click .set-options li": function(e) {
          e.preventDefault();
          return e.stopPropagation();
        },
        "click .remove-from-flow": function(e) {
          var self;
          self = this;
          console.log(this.model.get("type"));
          this.$el.slideUp("fast", function() {
            self.remove();
            return self.model.set("inFlow", false);
          });
          return e.stopPropagation();
        },
        "click .config-panel": function(e) {
          var editor;
          console.log(this.model.get("type"));
          return editor = new views.ElementEditor({
            model: this.model,
            view: this
          }).render();
        },
        "select": function(e) {
          return this.model.set("layout-item", true, {
            silent: true
          });
        },
        "deselect": function() {
          console.log("deselecting");
          return this.model.set("layout-item", false, {
            silent: true
          });
        },
        "change input": function(e) {
          this.model.set('customHeader', $(e.currentTarget).val());
          return e.stopImmediatePropagation();
        },
        "keyup textarea": function(e) {
          this.model.set('customText', $(e.currentTarget).val());
          return $(e.currentTarget).focus();
        }
      }
    });
    return window.views.SectionBuilder = Backbone.View.extend({
      el: 'section.builder-container',
      initialize: function() {
        var $el, that;
        this.render();
        that = this;
        $el = this.$el;
        this.collection.on("add", this.render, this);
        this.collection.on("change:inFlow", this.render, this);
        $el.droppable({
          accept: 'li, .builder-element',
          hoverClass: "dragging",
          activeClass: "dragging",
          tolerance: 'pointer',
          drop: function(event, ui) {
            var c, curr, temp;
            curr = that.currentModel;
            if ((curr.get("inFlow") === false || typeof curr.get("inFlow" === "undefined")) || that.fromSideBar === false) {
              c = curr.collection;
              if (c != null) {
                c.remove(curr, {
                  silent: true
                });
              }
              that.collection.add(curr, {
                silent: true
              });
              temp = new views.draggableElement({
                model: curr
              }).render().el;
              that.$el.append(temp);
              console.log("dropping in main builder");
              curr.set("inFlow", true);
              ui.draggable.data('dropped', true);
              $(ui.item).remove();
              return organizer.render();
            } else {
              return alert("That element is already on the page!");
            }
          }
        });
        $el.sortable({
          axis: 'y',
          tolerance: 'touch',
          handle: '.sort-element',
          items: '.builder-element',
          cursorAt: {
            top: 50
          },
          stop: function(e) {
            return e.stopPropagation();
          }
        });
        this.$el.selectable({
          filter: '.builder-element',
          tolerance: 'touch',
          cancel: '.builder-element',
          selecting: function(e, ui) {
            console.log("selecting");
            return $(".ui-selecting").addClass("selected-element").trigger("select");
          },
          unselecting: function(e, ui) {
            console.log("unselecting");
            return $(".ui-selecting").removeClass("selected-element").trigger("deselect");
          },
          selected: function(e, ui) {
            return $(".ui-selected").addClass("selected-element").trigger("select");
          },
          unselected: function(e, ui) {
            return $(".ui-selected").removeClass("selected-element").trigger("deselect");
          }
        });
        return this.currentModel = null;
      },
      render: function() {
        var $el, container, that;
        $el = this.$el;
        that = this;
        $el.empty();
        container = document.createDocumentFragment();
        _.each(this.collection.models, function(element) {
          if (element.get("inFlow") === false) {
            return;
          }
          return container.appendChild(new views.draggableElement({
            model: element
          }).render().el);
        });
        return $el.append(container);
      }
    });
  });

}).call(this);

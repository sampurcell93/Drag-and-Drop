// Generated by CoffeeScript 1.6.3
(function() {
  $(document).ready(function() {
    window.views.ElementOrganizer = Backbone.View.extend({
      initialize: function() {
        var that;
        this.controller = this.options.controller;
        this.wrapper = $(".control-section").eq(this.controller.index);
        this.$el = this.wrapper.find(".organize-elements");
        this.collection = this.options.collection;
        /* Render the list, then apply the drag and drop, and sortable functions.*/

        _.bindAll(this, "append", "render", "bindListeners");
        that = this;
        this.$el.sortable({
          axis: 'y',
          tolerance: 'touch',
          connectWith: 'ul',
          handle: '.sort-element',
          items: '> li.property',
          cancel: ".out-of-flow",
          start: function(e, ui) {
            that.oldIndex = ui.item.index() - 1;
            return that.collection.at(that.oldIndex).trigger("sorting");
          },
          stop: function(e, ui) {
            that.collection.reorder($(ui.item).index() - 1, that.oldIndex);
            return ui.item.removeClass("moving-sort");
          }
        });
        this.bindListeners();
        this.on("bindListeners", this.bindListeners, this);
        return this;
      },
      bindListeners: function() {
        var that;
        this.stopListening();
        that = this;
        return this.listenTo(this.collection, {
          "add": function(model, collection, options) {
            if (!((options.organizer != null) && options.organizer.render === false)) {
              return that.append(model, options);
            }
          },
          "remove": function() {
            if (that.collection.length === 0) {
              return $("<li/>").addClass("placeholder").text("No Content Here.").appendTo(that.$el);
            }
          }
        });
      },
      render: function(e) {
        var $el, index, outOfFlow, that;
        $el = this.$el;
        $el.children().not(".list-header, .placeholder").remove();
        if (this.collection.length === 0) {
          $("<li/>").addClass("placeholder").text("No Content Here.").appendTo(this.$el);
        }
        that = this;
        outOfFlow = [];
        index = that.options.index || sectionIndex;
        _.each(this.collection.models, function(el) {
          return that.append(el, {
            index: index,
            outOfFlow: false
          });
        });
        return this;
      },
      append: function(element, options) {
        var itemView, opts;
        this.$el.find(".placeholder").remove();
        if ((options != null) && (options.at != null)) {
          return this.appendAt(element, options);
        } else {
          opts = this.options;
          opts.model = element;
          $.extend(opts, options);
          itemView = new views.SortableElementItem(opts);
          return this.$el.append(itemView.render().el);
        }
      },
      appendAt: function(element, opts) {
        var itemView, pos;
        pos = opts.at + 1;
        opts.model = element;
        itemView = new views.SortableElementItem(opts).render().el;
        if (pos >= this.collection.length) {
          return this.$el.append(itemView);
        } else if (pos === 1) {
          return this.$el.children(".organizer-header").after(itemView);
        } else {
          return this.$el.children().eq(pos).before(itemView);
        }
      }
    });
    return window.views.SortableElementItem = Backbone.View.extend({
      tagName: 'li',
      className: 'property',
      template: $("#element-sortable-item").html(),
      initialize: function() {
        var that;
        that = this;
        this.listenTo(this.model, {
          "render": this.render,
          "remove": function(model, collection, opts) {
            if (!((opts.organizer != null) && opts.organizer.itemRender === false)) {
              return that.remove();
            }
          },
          "change:title": function(model) {
            return that.$el.children(".element-title").first().text(model.get("title"));
          },
          "change:inFlow": function(model, coll, opts) {
            if (model.get("inFlow") === false) {
              return that.$el.addClass("out-of-flow");
            } else {
              return that.$el.removeClass("out-of-flow");
            }
          }
        });
        return this.listenTo(this.model.get("child_els"), {
          "add": function(model, collection, opts) {
            if (!((opts.organizer != null) && opts.organizer.itemRender === false)) {
              return that.append(model, opts);
            }
          }
        });
      },
      render: function() {
        var $el, childList, self, that;
        self = this;
        $el = this.$el;
        $el.html(_.template(this.template, this.model.toJSON()));
        $el.draggable({
          cancel: '.sort-element, .activate-element, .destroy-element',
          revert: 'invalid',
          helper: 'clone',
          start: function(e, ui) {
            var children, clone;
            if (self.model.get("type") === "Property") {
              clone = self.model.clone();
              clone.collection = null;
              children = clone.get("child_els").clone();
              children.reset();
              clone.set("child_els", children, {
                no_history: true
              });
              return window.currentDraggingModel = clone;
            } else {
              return window.currentDraggingModel = self.model;
            }
          }
        });
        that = this;
        if (this.model.get("inFlow") === false) {
          this.$el.addClass("out-of-flow");
        } else {
          $el.removeClass("out-of-flow");
        }
        _.each(this.model.get("child_els").models, function(el) {
          return that.append(el);
        });
        childList = $el.children(".child-list");
        childList.sortable({
          items: '> li',
          axis: 'y',
          containment: 'parent',
          start: function(e, ui) {
            return that.origIndex = $(ui.item).index();
          },
          stop: function(e, ui) {
            return that.model.get("child_els").reorder($(ui.item).index(), that.origIndex);
          }
        });
        return this;
      },
      append: function(child, opts) {
        var $el, childList, elementItem;
        $el = this.$el;
        if ((opts != null) && (opts.at != null)) {
          this.appendAt(child, opts);
          return this;
        }
        childList = $el.children(".child-list");
        elementItem = new views.SortableElementItem({
          model: child,
          index: this.options.index
        }).render().el;
        if (child.get("inFlow") === false) {
          opts.outOfFlow = true;
          $el.addClass("out-of-flow");
          $("<div />").addClass("activate-element").text("m").prependTo($el);
          $("<div />").addClass("destroy-element").text("g").prependTo($el);
        }
        return childList.append(elementItem);
      },
      appendAt: function(child, opts) {
        var $el, itemView, pos, self;
        self = this;
        if ($.isArray(child)) {
          return _.each(child, function(model) {
            return self.appendAt(model);
          });
        } else {
          pos = opts.at;
          opts.model = child;
          $el = this.$el.children(".child-list");
          itemView = new views.SortableElementItem(opts).render().el;
          if ((this.model.get("child_els") != null) && pos >= this.model.get("child_els").length - 1) {
            return $el.append(itemView);
          } else if (pos === 0) {
            return $el.prepend(itemView);
          } else {
            $el.children().eq(pos - 1).after(itemView);
            return $el.children().eq(pos).before(itemView);
          }
        }
      },
      events: {
        "mousedown .sort-element": function(e) {
          return this.model.trigger("dragging");
        },
        "mouseup .sort-element": function(e) {
          return this.model.trigger("dropped");
        },
        "click .activate-element": function(e) {
          this.model.set("inFlow", true, {
            e: e
          });
          return e.stopPropagation();
        },
        "click .destroy-element": function(e) {
          this.model.destroy();
          return e.stopPropagation();
        },
        "mouseover": function(e) {
          this.model.trigger("sorting");
          return e.stopPropagation();
        },
        "mouseout": function(e) {
          if (!this.$el.hasClass("moving-sort")) {
            this.model.trigger("end-sorting");
          }
          return e.stopPropagation();
        }
      }
    });
  });

}).call(this);

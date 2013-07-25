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
        this.listenTo(this.collection, {
          "add": function(model, collection, options) {
            if (!((options.organizer != null) && options.organizer.render === false)) {
              return that.append(model, options);
            }
          }
        });
        /* Render the list, then apply the drag and drop, and sortable functions.*/

        _.bindAll(this, "append", "render");
        that = this;
        this.$el.sortable({
          axis: 'y',
          tolerance: 'touch',
          connectWith: 'ul',
          handle: '.sort-element',
          items: '> li',
          cancel: ".out-of-flow",
          start: function(e, ui) {
            that.oldIndex = ui.placeholder.index() - 1;
            return that.collection.at(that.oldIndex).trigger("sorting");
          },
          change: function(e, ui) {
            var incrementer;
            incrementer = 1;
            that.collection.reorder(that.oldIndex + incrementer, that.oldIndex);
            return that.oldIndex + incrementer;
          },
          stop: function(e, ui) {
            return ui.item.removeClass("moving-sort");
          }
        });
        return this;
      },
      render: function(e) {
        var $el, index, outOfFlow, that;
        $el = this.$el;
        $el.children().remove();
        that = this;
        outOfFlow = [];
        index = that.options.index || sectionIndex;
        _.each(this.collection.models, function(el) {
          if (el.get("inFlow") === false) {
            outOfFlow.push(el);
            return;
          }
          return that.append(el, {
            index: index,
            outOfFlow: false
          });
        });
        _.each(outOfFlow, function(out, i) {
          return that.append(out, {
            outOfFlow: true,
            index: index
          });
        });
        return this;
      },
      append: function(element, options) {
        var itemView, opts;
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
        console.log("Appending AT");
        pos = opts.at;
        opts.model = element;
        itemView = new views.SortableElementItem(opts).render().el;
        if (pos >= this.collection.length) {
          return this.$el.append(itemView);
        } else if (pos === 0) {
          return this.$el.prepend(itemView);
        } else {
          return this.$el.children().eq(pos).before(itemView);
        }
      }
    });
    return window.views.SortableElementItem = Backbone.View.extend({
      tagName: 'li class="property"',
      template: $("#element-sortable-item").html(),
      initialize: function() {
        var that;
        that = this;
        this.listenTo(this.model, {
          "render": this.render,
          "destroy": function() {
            var $el;
            return $el = that.$el;
          },
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
        var $el, childList, that;
        console.log("rendering item in organizer");
        $el = this.$el;
        $el.html(_.template(this.template, this.model.toJSON()));
        $el.draggable({
          zIndex: 11111,
          cancel: '.sort-element, .activate-element, .destroy-element',
          revert: 'invalid',
          helper: 'clone'
        });
        that = this;
        if (this.model.get("inFlow") === false) {
          $el.addClass("out-of-flow");
          $("<div />").addClass("activate-element").text("m").prependTo($el);
          $("<div />").addClass("destroy-element").text("g").prependTo($el);
        } else {
          $el.removeClass("out-of-flow");
        }
        this.outOfFlow = [];
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
        console.log("Appending child to org item", child);
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
          console.log("THSI SHIT IS STILL AN ARRAY");
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
          return this.model.set("inFlow", true, {
            e: e
          });
        },
        "click .destroy-element": function() {
          return this.model.destroy();
        },
        "mouseover": function() {
          return this.model.trigger("sorting");
        },
        "mouseout": function() {
          if (!this.$el.hasClass("moving-sort")) {
            return this.model.trigger("end-sorting");
          }
        }
      }
    });
  });

}).call(this);
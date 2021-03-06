// Generated by CoffeeScript 1.6.3
(function() {
  $(function() {
    var history;
    history = window.views.history = {};
    if (localStorage.settings == null) {
      localStorage.settings = {};
    }
    window.settings = {
      history_length: localStorage.settings.history_length || 50
    };
    window.models.Snap = Backbone.Model.extend();
    window.collections.Snapshots = Backbone.Collection.extend({
      model: window.models.Snap,
      initialize: function() {
        var snap;
        this.detached_head = false;
        snap = new models.Snap({
          snapshot: new collections.Elements()
        });
        snap.set({
          "opname": "Opened",
          "type": "Section Builder"
        });
        this.add(snap);
        return this;
      }
    });
    history.Snapshot = Backbone.View.extend({
      tagName: 'li',
      template: $("#snapshot").html(),
      initialize: function() {
        var self;
        this.controller = this.options.controller;
        this.current = this.options.current;
        self = this;
        this.listenTo(this.model, {
          "aheadOfFlow": function() {
            return self.$el.addClass("ahead-of-flow");
          },
          "insideFlow": function() {
            return self.$el.removeClass("ahead-of-flow");
          },
          "destroy": function() {
            return self.remove();
          },
          "select": function() {
            return self.$el.trigger("click");
          }
        });
        return this;
      },
      events: {
        "click": function(e) {
          var $t, ahead_flow, all_snaps, controller, inside_flow, model_index, snapshot;
          all_snaps = this.model.collection;
          model_index = all_snaps.indexOf(this.model);
          controller = this.controller;
          snapshot = this.model.get("snapshot").clone();
          this.current.last_snap = this.$el.siblings(".selected-history").first().index() - 1;
          $t = $(e.currentTarget);
          ahead_flow = _.filter(this.model.collection.models, function(m, i) {
            return i > model_index;
          });
          inside_flow = _.filter(this.model.collection.models, function(m, i) {
            return i <= model_index;
          });
          _.each(ahead_flow, function(snap) {
            return snap.set("aheadOfFlow", true).trigger("aheadOfFlow");
          });
          _.each(inside_flow, function(snap) {
            return snap.set("aheadOfFlow", false).trigger("insideFlow");
          });
          controller.model.set("currentSection", snapshot);
          controller.organizer.collection = snapshot;
          controller.organizer.trigger("bindListeners");
          controller.organizer.render();
          controller.builder.collection = snapshot;
          controller.builder.scaffold.set("child_els", snapshot);
          if (model_index < all_snaps.length - 1) {
            all_snaps.detached_head = true;
          } else {
            all_snaps.detached_head = false;
          }
          this.current.collection = snapshot;
          this.current.bindListeners();
          e.stopPropagation();
          e.stopImmediatePropagation();
          $t.addClass("selected-history").siblings().removeClass("selected-history");
          return false;
        }
      },
      render: function() {
        this.$el.html(_.template(this.template, this.model.toJSON()));
        return this;
      }
    });
    return history.HistoryList = Backbone.View.extend({
      tagName: 'div',
      className: 'history-modal',
      initialize: function() {
        this.controller = this.options.controller;
        this.snapshots = this.options.snapshots;
        _.bindAll(this, "makeHistory", "render", "append", "bindListeners");
        this.bindListeners();
        return this;
      },
      bindListeners: function(collection) {
        var coll, self;
        this.stopListening();
        coll = collection || this.collection;
        this.listenTo(coll, {
          "all": this.makeHistory
        });
        self = this;
        _.each(coll.models, function(model) {
          return self.bindIndividualListener(model);
        });
        return this;
      },
      bindIndividualListener: function(model) {
        var children, self;
        cc("calling bindIndividualListener");
        children = model.get("child_els");
        self = this;
        this.listenTo(model, "change", this.modelChange);
        this.listenTo(children, "all", this.makeHistory);
        _.each(children.models, function(child) {
          return self.bindIndividualListener(child);
        });
        return this;
      },
      oneAhead: function(snapshot) {
        this.collection = snapshot;
        return this;
      },
      selectLast: function() {
        var last;
        last = this.last_snap;
        if (last < this.snapshots.length && last >= 0) {
          this.snapshots.at(last).trigger("select");
        }
        return this;
      },
      modelChange: function(model, options) {
        var snap;
        options = _.extend({}, options);
        console.log(model, options, "changed");
        if (options.no_history !== true) {
          this.deleteForwardChanges();
          snap = this.takeSnapshot(options.opname || "Modified", model);
          this.snapshots.add(snap);
          this.append(snap);
          return this;
        }
        return this;
      },
      makeHistory: function(operation, subject, collection, options) {
        var op, ops, snap;
        if (operation === "add") {
          this.bindIndividualListener(subject);
        }
        console.log("Storing history with operator " + operation);
        ops = ["change", "add", "remove", "destroy"];
        if (ops.indexOf(operation) === -1) {
          return;
        }
        if (operation === "change") {
          options = collection;
        }
        if (options == null) {
          options = {};
        }
        if (!((options != null) && options.no_history === true)) {
          op = options.opname || operation;
          subject = options.subject || subject;
          this.deleteForwardChanges();
          snap = this.takeSnapshot(op, subject);
          if (snap !== null) {
            this.snapshots.add(snap);
            this.append(snap);
          }
        }
        return this;
      },
      takeSnapshot: function(op, subject) {
        var clone, e, snap;
        if ((subject == null) || (op == null)) {
          return null;
        }
        if (subject instanceof models.Element === true) {
          subject = subject.get("type");
        }
        clone = null;
        if (this.controller.model.get("currentSection") != null) {
          try {
            clone = this.controller.model.get("currentSection").clone();
          } catch (_error) {
            e = _error;
            return false;
          }
        }
        snap = new models.Snap({
          snapshot: clone
        });
        snap.set({
          "opname": op,
          "type": subject || "element"
        });
        if (this.snapshots.length >= window.settings.history_length && (this.snapshots.at(0) != null)) {
          this.snapshots.at(0).destroy();
        }
        return snap;
      },
      deleteForwardChanges: function() {
        var ahead;
        if (this.snapshots.detached_head === true) {
          this.snapshots.detached_head = false;
          ahead = _.filter(this.snapshots.models, function(snap, i) {
            return snap.get("aheadOfFlow") === true;
          });
          _.each(ahead, function(snap) {
            return snap.destroy();
          });
        }
        return this;
      },
      render: function() {
        var self;
        self = this;
        this.$el.empty();
        if (this.snapshots.length === 0) {
          $("<li/>").addClass("placeholder p10 center").text("No History Here.").appendTo(this.$el);
        }
        _.each(this.snapshots.models, function(snapshot) {
          return self.append(snapshot);
        });
        return this;
      },
      append: function(snapshot) {
        var $el, SnapItem, item;
        $el = this.$el;
        this.$(".placeholder").hide();
        this.$(".selected-history").removeClass("selected-history");
        SnapItem = new history.Snapshot({
          model: snapshot,
          controller: this.controller,
          current: this
        });
        $el.prepend(item = SnapItem.render().el);
        $(item).addClass("selected-history");
        return this;
      }
    });
  });

}).call(this);

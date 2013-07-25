// Generated by CoffeeScript 1.6.3
(function() {
  $(document).ready(function() {
    window.sectionIndex = window.currIndex = 0;
    window.models.DataType = Backbone.Model.extend({
      url: function() {
        return "/class/";
      }
    });
    window.models.Property = Backbone.Model.extend();
    /* COLLECTIONS*/

    window.collections.AllSections = Backbone.Collection.extend({
      model: models.SectionController
    });
    window.collections.Properties = Backbone.Collection.extend({
      model: models.Property
    });
    window.collections.ClassList = Backbone.Collection.extend({
      url: "/class",
      model: models.DataType
    });
    window.allSections = new collections.AllSections();
    /* IMPORTANT: Order of oparations: Model generated blank, added to collection of sections ->
        View generated on blank template, rendered ->
        Model populated, elements like builder rendered and linked to their els, made
        possible by rendering the view first.
    */

    window.views.SectionControllerView = Backbone.View.extend({
      tagName: 'div',
      wrap: '.section-builder-wrap',
      template: $("#controller-wrap").html(),
      render: function(i) {
        this.$el.addClass("control-section").attr("id", "section-" + i).html(_.template(this.template, this.model.toJSON()));
        this.$el.droppable({
          accept: '.builder-element',
          over: function(e, ui) {
            return console.log(ui);
          },
          out: function(e, ui) {
            return console.log(ui);
          },
          drop: function(e, ui) {
            var models;
            models = window.currentDraggingModel;
            if ($.isArray(models) === true) {
              return _.each(models, function(model) {
                return model.set("inFlow", false);
              });
            } else {
              return models.set("inFlow", false);
            }
          }
        });
        return this;
      },
      events: {
        'click .generate-section': 'generateSection',
        'click .save-section': 'saveSection',
        'click .view-layouts': function() {
          return window.layoutCollection = new collections.Layouts();
        },
        'click .view-sections': function(e) {
          $(e.currentTarget).toggleClass("active");
          return $("#existing-sections").animate({
            height: 'toggle'
          }, 200);
        },
        'click .configure-interface': function() {
          return this.model.get("builder").$el.toggleClass("no-grid");
        },
        'keyup .section-title': function(e) {
          var $t, title;
          $t = $(e.currentTarget);
          title = $t.val();
          if (title === "") {
            title = $t.data("previous-val") || "New Section";
          }
          this.model.set("title", title);
          e.stopPropagation();
          return e.stopImmediatePropagation();
        },
        'focus .section-title': function(e) {
          return $(e.currentTarget).data("previous-val", $(e.currentTarget).val());
        },
        'blur .section-title': function(e) {
          var $t;
          $t = $(e.currentTarget);
          if ($t.val() === "") {
            return $t.val($t.data("previous-val") || "New Section");
          }
        }
      },
      setProps: function() {
        var opts, that;
        that = this;
        if (typeof opts === "undefined" || opts === null) {
          opts = {};
        }
        this.model.index = allSections.length - 1;
        this.builder = new views.SectionBuilder({
          controller: this.model,
          collection: this.model.get("currentSection")
        });
        this.organizer = new views.ElementOrganizer({
          controller: this.model,
          collection: this.model.get("currentSection")
        });
        this.classes = new collections.ClassList({
          controller: this.model
        });
        this.classes.fetch({
          success: function(coll) {
            that.dataview = new views.DataView({
              collection: coll,
              controller: that.model
            });
            return that.selectedData = new views.SelectedDataList({
              collection: that.model.get("properties"),
              controller: that.model
            });
          },
          failure: function() {
            return alert("could not get data from URL " + that.url);
          }
        });
        this.genericCollection = new collections.GenericElements();
        this.genericCollection.fetch({
          success: function(coll) {
            return that.genericList = new views.GenericList({
              collection: coll,
              controller: that.model
            });
          }
        });
        this.model.set({
          builder: this.builder,
          organizer: this.organizer
        });
        return this;
      },
      generateSection: function(e) {
        var $t;
        if (e != null) {
          $t = $(e.currentTarget);
          $t.toggleClass("viewing-layout");
          if ($t.hasClass("viewing-layout")) {
            $t.text("View Configuration");
          } else {
            $t.text("View Section Builder");
          }
        }
        return this.$el.find(this.wrap).slideToggle('fast');
      },
      saveSection: function() {
        var copy, title;
        title = this.$el.find(".section-title").val();
        if (title === "" || typeof title === "undefined" || title === "New Section") {
          alert("You need to enter a title");
          return;
        }
        console.log(title);
        copy = new models.SectionController();
        copy.set({
          currentSection: this.model.get("currentSection"),
          section_title: title,
          properties: this.model.get("properties")
        });
        console.log(copy.get("currentSection").models);
        return copy.save(null, {
          success: function() {
            $("<div />").addClass("modal center").html("You saved the section").appendTo(document.body);
            $(document.body).addClass("active-modal");
            return $(".modal").delay(2000).fadeOut("fast", function() {
              $(this).remove();
              return $(document.body).removeClass("active-modal");
            });
          }
        });
      }
    });
    window.views.AllSectionControllers = Backbone.View.extend({
      el: '.container',
      initialize: function() {
        var self;
        self = this;
        this.render();
        return this.listenTo(this.collection, "add", function(e) {
          return self.append(e);
        });
      },
      render: function() {
        var $el, self;
        $el = this.$el;
        $el.empty();
        self = this;
        _.each(this.collection.models, function(controller, i) {
          return self.append(controller);
        });
        return this;
      },
      append: function(model) {
        var view;
        console.log("append tab");
        view = new views.SectionControllerView({
          model: model
        });
        this.$el.append($(view.render(this.collection.models.length - 1).el));
        view.setProps();
        return this;
      }
    });
    window.views.SectionTabItem = Backbone.View.extend({
      template: $("#tab-item").html(),
      tagName: 'li',
      initialize: function() {
        return this.listenTo(this.model, "change:title", this.render);
      },
      render: function(i) {
        if (typeof i === "string" || typeof i === "number") {
          this.$el.attr("data-id", i);
        }
        this.$el.html(_.template(this.template, {
          title: this.model.get("title")
        }));
        this.$el.droppable({
          tolerance: 'pointer',
          revert: 'invalid',
          accept: '.builder-element',
          over: function(e, ui) {
            var $t, checkHover;
            $t = $(e.target).addClass("over");
            checkHover = function() {
              var clone, toSection;
              clone = $(ui.item).clone();
              if ($t.hasClass("over")) {
                $t.trigger("click");
                toSection = $(".control-section").eq(currIndex).find(".generate-section");
                if (!toSection.hasClass("viewing-layout")) {
                  toSection.trigger("click");
                }
              }
              return console.log(currIndex);
            };
            return window.setTimeout(checkHover, 500);
          },
          out: function(e) {
            return $(e.target).removeClass("over");
          },
          drop: function(e, ui) {}
        });
        return this;
      },
      events: {
        "mouseover": function(e) {
          var self;
          this.hovering = true;
          self = this;
          return window.setTimeout(function() {
            if (self.hovering === true) {
              $(self.el).find(".remove").fadeIn("fast");
              e.stopPropagation();
              return e.stopImmediatePropagation();
            }
          }, 400);
        },
        "mouseleave": function() {
          this.hovering = false;
          return this.$el.find(".remove").fadeOut("fast");
        },
        "click": function(e) {
          var $t, index;
          window.currIndex = this.$el.index() - 1;
          $t = $(e.currentTarget);
          index = $t.addClass("current-tab").data("id");
          $t.siblings().removeClass("current-tab");
          $(".control-section").hide();
          return $("#section-" + index).delay(200).show();
        }
      }
    });
    window.views.SectionTabs = Backbone.View.extend({
      el: ".tabs",
      initialize: function() {
        this.listenTo(this.collection, {
          "add": this.render,
          "remove": this.render
        });
        return this.render();
      },
      render: function() {
        var $el, len;
        $el = this.$el;
        $el.children().not(".add-section").remove();
        len = allSections.models.length;
        return _.each(allSections.models, function(section, i) {
          var tab;
          tab = new views.SectionTabItem({
            model: section
          }).render(i).el;
          $el.append(tab);
          if (i === len - 1) {
            return $(tab).hide().animate({
              "width": "show"
            }, 300).addClass("current-tab");
          }
        });
      },
      events: {
        "click .add-section": function(e) {
          sectionIndex += 1;
          allSections.add(new models.SectionController());
          e.stopImmediatePropagation();
          $(".control-section").hide();
          return $("#section-" + sectionIndex).show();
        }
      }
    });
    window.models.SectionController = Backbone.Model.extend({
      url: '/section',
      defaults: function() {
        return {
          "currentSection": new collections.Elements(),
          "properties": new collections.Properties()
        };
      }
    });
    window.views.DataView = Backbone.View.extend({
      initialize: function() {
        this.controller = this.options.controller;
        this.wrapper = $(".control-section").eq(this.controller.index);
        this.$el = this.wrapper.find(".class-list");
        _.bindAll(this, 'render');
        return this.render();
      },
      render: function() {
        var that;
        that = this;
        this.$el.empty();
        return _.each(this.collection.models, function(prop) {
          if (!prop.rendered) {
            prop.rendered = true;
            return that.$el.append(new views.DataSingle({
              model: prop,
              index: that.controller.index
            }).render().el);
          }
        });
      },
      events: {
        "click .new-data-type": function() {
          var mod;
          mod = new DataType({
            name: 'Private',
            properties: []
          });
          this.collection.add(mod);
          return this.ender();
        }
      }
    });
    window.views.DataSingle = Backbone.View.extend({
      template: $("#data-type").html(),
      updateTemplate: $("#add-property").html(),
      tagName: 'li',
      initialize: function() {
        return _.bindAll(this, 'render');
      },
      render: function() {
        var $el, i, newProperty, prop, props, _i, _len;
        $el = $(this.el);
        $el.prepend(_.template(this.template, this.model.toJSON()));
        props = this.model.get("properties");
        console.log(this.model);
        for (i = _i = 0, _len = props.length; _i < _len; i = ++_i) {
          prop = props[i];
          newProperty = new models.Property(prop);
          newProperty.set("className", this.model.get("name"));
          $el.append(new views.PropertyItem({
            model: newProperty,
            index: this.options.index,
            editable: true
          }).render().el);
        }
        return this;
      },
      events: {
        "click .add-property": function(e) {
          var newProp;
          newProp = new models.Property({
            name: 'Change Me',
            className: this.model.get("name")
          });
          $(this.el).append(new views.PropertyItem({
            model: newProp,
            index: this.options.index
          }).render().el);
          return allSections.at(this.options.index).get("properties").add(newProp);
        },
        "click .close": function(e) {
          var that;
          that = this;
          return $(e.currentTarget).closest("li").fadeOut("fast", function() {
            $(this).remove();
            return that.model.destroy();
          });
        },
        "click .hide-properties": function(e) {
          var $t;
          $t = $(e.currentTarget);
          $t.children(".icon").toggleClass("flipped");
          return $t.siblings("li").fadeToggle("fast");
        }
      }
    });
    window.views.SelectedDataList = Backbone.View.extend({
      template: $("#configure-property").html(),
      initialize: function() {
        this.controller = this.options.controller;
        this.wrapper = $(".control-section").eq(this.controller.index);
        this.$el = this.wrapper.find(".property-editor");
        this.listenTo(this.collection, {
          "add": this.append
        });
        _.bindAll(this, 'render');
        return this.render();
      },
      render: function() {
        var $el, self;
        $el = this.$el;
        $el.empty();
        self = this;
        return _.each(this.collection.models, function(prop) {
          return self.append(prop);
        });
      },
      append: function(prop) {
        return this.$el.append(new views.PropertyItemEditor({
          model: prop
        }).render().el);
      }
    });
    window.views.PropertyItemEditor = Backbone.View.extend({
      template: $("#property-item-editor").html(),
      tagName: 'li',
      initialize: function() {
        var self;
        self = this;
        return this.listenTo(this.model, {
          "remove": function() {
            return self.$el.fadeOut("fast", function() {
              return self.remove();
            });
          }
        });
      },
      render: function() {
        $(this.el).append(_.template(this.template, this.model.toJSON()));
        return this;
      }
    });
    window.views.PropertyItem = Backbone.View.extend({
      template: $("#property-item").html(),
      tagName: 'li class="property" ',
      render: function() {
        var item;
        item = $.extend({}, this.model.toJSON(), this.options);
        this.$el.append(_.template(this.template, item));
        this.$el.trigger("click");
        return this;
      },
      events: {
        "click": function(e) {
          var $t, currentSection, model, selected;
          $t = $(e.currentTarget);
          $t.toggleClass("selected");
          selected = this.model.selected;
          currentSection = allSections.at(this.options.index).get("currentSection");
          this.model.selected = selected ? false : true;
          if (this.model.selected === true) {
            console.log(allSections.at(this.options.index));
            allSections.at(this.options.index).get("properties").add(this.model);
            model = this.model.toJSON();
            model.title = model.className + "." + model.name;
            model.property = this.model;
            model.property.name = model.name;
            model.type = "Property";
            if (this.elementModel == null) {
              this.elementModel = new models.Element(model);
            }
            return currentSection.add(this.elementModel);
          } else {
            allSections.at(this.options.index).get("properties").remove(this.model);
            return currentSection.remove(this.elementModel);
          }
        },
        "keyup": function(e) {
          var $t, val;
          $t = $(e.currentTarget);
          val = $t.find("div").text();
          return this.model.set("name", val);
        }
      }
    });
    allSections.add(new models.SectionController());
    window.sectionTabs = new views.SectionTabs({
      collection: allSections
    });
    return window.sectionList = new views.AllSectionControllers({
      collection: allSections
    });
  });

}).call(this);

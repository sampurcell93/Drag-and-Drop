// Generated by CoffeeScript 1.6.3
(function() {
  $(document).ready(function() {
    var sampleClasses;
    window.sectionIndex = window.currIndex = 0;
    sampleClasses = [
      {
        "name": "User",
        "properties": [
          {
            "name": "First Name"
          }, {
            "name": "Last Name"
          }, {
            "name": "Street Address"
          }, {
            "name": "City"
          }, {
            "name": "Zip"
          }
        ]
      }
    ];
    window.models.DataType = Backbone.Model.extend({
      url: function() {
        return "/class/";
      }
    });
    window.models.Property = Backbone.Model.extend({});
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
      initialize: function() {
        var self;
        self = this;
        return this.listenTo(this.model, {
          "change:title": function(model) {
            return self.$el.find(".section-title .title-wrap").text(model.get("title"));
          },
          "destroy": function() {
            return self.remove();
          }
        });
      },
      render: function() {
        this.$el.addClass("control-section").html(_.template(this.template, this.model.toJSON()));
        $(".container").droppable({
          accept: '.builder-element, .draggable-modal',
          drop: function(e, ui) {
            var models;
            models = window.currentDraggingModel;
            if (models == null) {
              return false;
            }
            if ($.isArray(models) === true) {
              ui.helper.remove();
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
        'click .no-grid': function() {
          return this.$el.toggleClass("no-grid");
        },
        'click .section-title': function(e) {
          var modal, self;
          self = this;
          modal = window.launchModal(_.template($("#section-change").html(), {
            title: this.model.get("title")
          }) + "<button class='confirm m10'>OK</button>");
          modal.delegate(".change-section-title", "keyup", function() {
            var $t, title;
            $t = $(this);
            title = $t.val();
            if (title === "") {
              title = $t.data("previous-val") || "Default Title";
            }
            return self.model.set("title", title);
          });
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
            return $t.val($t.data("previous-val") || "");
          }
        },
        "click .settings": function() {
          var modal, temp;
          temp = $("#settings-template").html();
          modal = window.launchModal(_.template(temp + "<button class='confirm'>OK</button>", window.settings));
          return modal.find(".hist-length").slider({
            value: window.settings.history_length,
            step: 1,
            min: 0,
            max: 100,
            slide: function(e, ui) {
              window.settings.history_length = ui.value;
              localStorage.settings.history_length = ui.value;
              return $(".history-length-label").text(ui.value);
            }
          });
        }
      },
      setProps: function() {
        var $o_el, css_modal, existing_modal, hist_modal, opts, props_modal, section, that, toolbelt;
        that = this;
        if (typeof opts === "undefined" || opts === null) {
          opts = {};
        }
        this.model.index = allSections.length - 1;
        this.existingSectionCollection = new collections.Elements();
        this.existingSectionCollection.fetch({
          success: function(coll) {
            return that.existingSectionsList = new views.ExistingSectionsList({
              collection: coll,
              controller: that.model
            });
          }
        });
        section = this.model.get("currentSection");
        this.snaps = new collections.Snapshots();
        this.histList = new views.history.HistoryList({
          controller: this,
          snapshots: this.snaps,
          collection: section
        });
        this.builder = new views.SectionBuilder({
          controller: this.model,
          collection: section
        });
        this.organizer = new views.ElementOrganizer({
          controller: this.model,
          collection: section
        });
        $o_el = this.$el.find(".accessories");
        toolbelt = this.$(".toolbelt");
        hist_modal = window.launchDraggableModal(this.histList.render().el, null, toolbelt, "History - Recent <span class='history-length-label'>15</span>");
        hist_modal.addClass("history");
        props_modal = window.launchDraggableModal($("<ul/>"), null, toolbelt, "Editable Attributes");
        props_modal.addClass("quick-props");
        css_modal = window.launchDraggableModal($("<ul/>"), null, toolbelt, "Skin Format");
        css_modal.addClass("quick-css");
        existing_modal = window.launchDraggableModal($("<ul/>").addClass("existing-sections-layouts"), null, toolbelt, "Recent Sections");
        existing_modal.addClass("existing-modal");
        $o_el.droppable({
          accept: '.moved',
          greedy: true,
          out: function(e, ui) {
            return ui.draggable.addClass("moved");
          },
          drop: function(e, ui) {
            return ui.draggable.css({
              "position": "relative"
            }).removeClass("moved");
          }
        });
        this.classes = new collections.ClassList(sampleClasses);
        this.classes.controller = this.model;
        this.dataview = new views.DataView({
          collection: this.classes,
          controller: this.model
        });
        this.selectedData = new views.SelectedDataList({
          collection: this.model.get("properties"),
          controller: this.model
        });
        this.genericList = new views.GenericList({
          controller: this.model
        });
        this.layouts = new views.LayoutList({
          controller: this.model
        });
        this.model.set({
          builder: this.builder,
          organizer: this.organizer,
          snaps: this.snaps,
          controller: this
        });
        return this;
      },
      renderComponents: function(components) {
        var component, _i, _len;
        for (_i = 0, _len = components.length; _i < _len; _i++) {
          component = components[_i];
          this[component].render();
        }
        return this.model.saved = true;
      },
      generateSection: function(e) {
        var $t;
        if (e != null) {
          $t = $(e.currentTarget);
          $t.toggleClass("viewing-layout");
        }
        return this.$el.find(this.wrap).slideToggle('fast');
      },
      saveSection: function() {
        var copy, title;
        title = this.model.get("title");
        if (title === "" || typeof title === "undefined" || title === "Default Section Title") {
          alert("You need to enter a label for the section before you can save it!");
          return false;
        }
        copy = new models.SectionController();
        copy.set({
          currentSection: this.model.get("currentSection"),
          section_title: title,
          properties: this.model.get("properties")
        });
        this.model.saved = true;
        copy.save(null, {
          success: function() {
            $("<div />").addClass("modal center").html("Section <em>\"" + title + "\"</em> successfully saved!").appendTo(document.body);
            $(document.body).addClass("active-modal");
            return $(".modal").delay(1200).fadeOut("fast", function() {
              $(this).remove();
              return $(document.body).removeClass("active-modal");
            });
          }
        });
        return true;
      }
    });
    window.views.AllSectionControllers = Backbone.View.extend({
      el: '.container',
      initialize: function() {
        var self;
        self = this;
        this.render();
        return this.listenTo(this.collection, "add", function(model) {
          return self.append(model);
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
        window.currIndex = this.collection.length - 1;
        view = new views.SectionControllerView({
          model: model
        });
        this.$el.append($(view.render().el));
        view.setProps().renderComponents(["builder", "organizer"]);
        return this;
      }
    });
    window.views.SectionTabItem = Backbone.View.extend({
      template: $("#tab-item").html(),
      tagName: 'li',
      initialize: function() {
        var self;
        self = this;
        return this.listenTo(this.model, "change:title", function(m, c, o) {
          if (!((o != null) && o.no_tab === true)) {
            return self.render();
          }
        });
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
          accept: '.builder-element',
          over: function(e, ui) {
            var $t, checkHover;
            $t = $(e.target).addClass("over");
            checkHover = function() {
              var clone, toSection;
              clone = $(ui.item).clone();
              if ($t.hasClass("over")) {
                $t.trigger("click");
                toSection = $(".control-section").eq(window.currIndex).find(".generate-section");
                if (!toSection.hasClass("viewing-layout")) {
                  return toSection.trigger("click");
                }
              }
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
        "keyup [contentEditable]": function(e) {
          return this.model.set("title", $(e.currentTarget).text(), {
            no_tab: true
          });
        },
        "click .remove": function(e) {
          var collection, index, sure;
          if (this.model.saved === true) {
            this.model.destroy();
          } else {
            sure = confirm("Are you sure you want to close this builder? You haven't saved it.");
            if (sure === true) {
              this.model.destroy();
            } else {
              return;
            }
          }
          index = this.$el.index() - 1;
          collection = this.model.collection;
          if (index === window.currIndex) {
            if (index + 1 < collection.length) {
              this.$el.next().trigger("click");
            } else if (index - 1 >= 0) {
              this.$el.prev().trigger("click");
            } else {
              window.currIndex = 0;
            }
          }
          return e.stopPropagation();
        },
        "click": function(e) {
          var $t, index;
          window.currIndex = this.$el.index() - 1;
          $t = $(e.currentTarget);
          index = $t.addClass("current-tab").data("id");
          $t.siblings().removeClass("current-tab");
          $(".control-section").hide();
          return $(".control-section").eq(window.currIndex).show();
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
            }, 300).addClass("current-tab").trigger("click");
          }
        });
      },
      events: {
        "click .add-section": function(e) {
          return allSections.add(new models.SectionController());
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
      },
      initialize: function() {
        var self;
        this.saved = true;
        self = this;
        this.get("currentSection").on("all", function() {
          return self.saved = false;
        });
        return this.on("all", function() {
          return self.saved = false;
        });
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
        return _.each(this.collection.models, function(prop, i) {
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
        for (i = _i = 0, _len = props.length; _i < _len; i = ++_i) {
          prop = props[i];
          newProperty = new models.Property(prop);
          newProperty.set("className", this.model.get("name"));
          $el.append(new views.PropertyItem({
            model: newProperty,
            index: this.options.index,
            editable: false
          }).render().el);
        }
        return this;
      },
      events: {
        "click .add-property": function(e) {
          var newProp, prop;
          newProp = new models.Property({
            className: this.model.get("name")
          });
          this.$el.append(prop = new views.PropertyItem({
            model: newProp,
            index: this.options.index,
            editable: true
          }).render().el);
          return this.$el.children().last().find("input[type=text]").focus();
        },
        "click .close": function(e) {
          var that;
          that = this;
          return $(e.currentTarget).toggleClass("flipped").closest("li").fadeOut("fast", function() {
            $(this).remove();
            return that.model.destroy();
          });
        },
        "click .hide-properties": function(e) {
          var $t;
          $t = $(e.currentTarget);
          $t.find("span").toggleClass("flipped");
          return $t.siblings("li").fadeToggle("fast");
        }
      }
    });
    window.views.SelectedDataList = Backbone.View.extend({
      template: $("#configure-property").html(),
      initialize: function() {
        var self;
        this.controller = this.options.controller;
        this.wrapper = $(".control-section").eq(this.controller.index);
        this.$el = this.wrapper.find(".property-editor");
        self = this;
        this.listenTo(this.collection, {
          "add": this.append,
          "remove": function() {
            if (self.collection.length === 0) {
              return self.$(".placeholder").show();
            }
          }
        });
        _.bindAll(this, 'render');
        return this.render();
      },
      render: function() {
        var $el, self;
        $el = this.$el;
        self = this;
        return _.each(this.collection.models, function(prop) {
          return self.append(prop);
        });
      },
      append: function(prop) {
        this.$(".placeholder").hide();
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
          },
          "change:name": this.render
        });
      },
      render: function() {
        this.$el.html(_.template(this.template, this.model.toJSON()));
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
        return this;
      },
      chooseProp: function(e) {
        var $t, currentSection, model, selected;
        if (e != null) {
          $t = $(e.currentTarget);
          $t.closest(".property").toggleClass("selected");
          e.stopPropagation();
        }
        selected = this.model.selected;
        currentSection = allSections.at(window.currIndex).get("currentSection");
        this.model.selected = selected ? false : true;
        if (this.model.selected === true) {
          allSections.at(window.currIndex).get("properties").add(this.model);
          model = this.model.toJSON();
          model.title = model.className + "." + model.name;
          model.view = "Input";
          model.property = this.model;
          model.property.name = model.name || "";
          model.type = "Property";
          console.log(model.property);
          if (this.elementModel == null) {
            this.elementModel = new models.Element(model);
          }
          return currentSection.add(this.elementModel);
        } else {
          allSections.at(window.currIndex).get("properties").remove(this.model);
          return currentSection.remove(this.elementModel);
        }
      },
      events: {
        "click .icon-multiply": function() {
          this.model.destroy();
          return this.remove();
        },
        "click .choose-prop": "chooseProp",
        "keyup input": function(e) {
          var $t, val;
          $t = $(e.currentTarget);
          val = $t.val();
          this.model.set("name", val);
          if (this.elementModel != null) {
            return this.elementModel.set("title", val).trigger("render");
          }
        },
        'keydown': function(e) {
          var key;
          key = e.keyCode || e.which;
          if (key === 13) {
            this.$el.siblings(".add-property").trigger("click");
            this.$el.next().trigger("click");
            console.log(this.$el.next());
            e.preventDefault();
            return false;
          }
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

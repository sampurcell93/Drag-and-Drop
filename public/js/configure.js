// Generated by CoffeeScript 1.6.3
(function() {
  $(document).ready(function() {
    var classes, dataview, elements, properties, selectedData;
    dataview = null;
    selectedData = null;
    window.sectionController = null;
    window.models.DataType = Backbone.Model.extend({
      url: function() {
        return "/class/";
      }
    });
    window.models.Property = Backbone.Model.extend({
      initialize: function() {
        if (Math.random() > .6) {
          this.selected = true;
          return properties.add(this);
        }
      }
    });
    /* COLLECTIONS*/

    window.collections.Properties = Backbone.Collection.extend({
      initialize: function() {
        return this.on("remove", function() {
          return console.log("removing element from collection");
        });
      },
      swapItems: function(index1, index2) {
        var temp;
        temp = this.models[index1];
        this.models[index1] = this.models[index2];
        return this.models[index2] = temp;
      },
      model: models.Property
    });
    window.collections.ClassList = Backbone.Collection.extend({
      url: "/class",
      model: models.DataType,
      initialize: function() {
        var that;
        that = this;
        this.fetch({
          success: function() {
            var sectionController;
            dataview = new views.DataView({
              collection: that
            });
            selectedData = new views.SelectedDataList({
              collection: properties
            });
            return sectionController = new views.SectionController();
          },
          failure: function() {
            return alert("could not get data from URL " + that.url);
          }
        });
        return this;
      }
    });
    window.views.SectionController = Backbone.View.extend({
      el: '.control-section',
      wrap: '.section-builder-wrap',
      initialize: function() {
        return this.selected = properties;
      },
      events: {
        'click .generate-section': 'generateSection',
        'click .save-section': 'saveSection',
        'click .view-layouts': function() {
          return window.layoutCollection = new collections.Layouts();
        }
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
        $(this.wrap).slideToggle('fast');
        if (typeof builder === "undefined" || builder === null) {
          window.currentSection = this.constructElementCollection();
          window.builder = new views.SectionBuilder({
            collection: currentSection
          });
          return window.organizer = this.organizer = new views.ElementOrganizer({
            collection: currentSection
          });
        } else {
          return console.log("nope, shit is there");
        }
      },
      saveSection: function() {
        return _.each(currentSection.models, function(model) {
          return console.log(model.toJSON());
        });
      },
      constructElementCollection: function() {
        var elements;
        elements = new collections.Elements();
        _.each(this.selected.models, function(prop) {
          return elements.add(new models.Element({
            property_name: prop.get("name")
          }));
        });
        return elements;
      }
    });
    window.views.DataView = Backbone.View.extend({
      el: '#class-list',
      initialize: function() {
        _.bindAll(this, 'render');
        return this.render();
      },
      render: function() {
        var that;
        that = this;
        return _.each(this.collection.models, function(prop) {
          if (!prop.rendered) {
            prop.rendered = true;
            return $(that.el).append(new views.DataSingle({
              model: prop
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
          $el.append(new views.PropertyItem({
            model: newProperty
          }).render().el);
        }
        return this;
      },
      events: {
        "click .add-property": function(e) {
          var newProp;
          newProp = new models.Property({
            name: 'Change Me'
          });
          $(this.el).append(new views.PropertyItem({
            model: newProp
          }).render().el);
          return properties.add(newProp);
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
      el: '.property-editor',
      template: $("#configure-property").html(),
      initialize: function() {
        _.bindAll(this, 'render');
        return this.render();
      },
      render: function() {
        var $el;
        $el = $(this.el);
        $el.empty();
        return _.each(this.collection.models, function(prop) {
          $el.append(new views.PropertyItemEditor({
            model: prop
          }).render().el);
          return this;
        });
      }
    });
    window.views.PropertyItemEditor = Backbone.View.extend({
      template: $("#property-item-editor").html(),
      tagName: 'li',
      render: function() {
        $(this.el).append(_.template(this.template, this.model.toJSON()));
        return this;
      }
    });
    window.views.PropertyItem = Backbone.View.extend({
      template: $("#property-item").html(),
      tagName: function() {
        var id, selected;
        selected = this.model.selected === true ? "selected" : "";
        id = this.options.sortable === true ? properties.indexOf(this.model) : "";
        return 'li class="property ' + selected + '" data-prop-id="' + id + '"';
      },
      render: function() {
        $(this.el).append(_.template(this.template, this.model.toJSON()));
        return this;
      },
      events: {
        "click": function(e) {
          var $t, selected;
          $t = $(e.currentTarget);
          $t.toggleClass("selected");
          selected = this.model.selected;
          this.model.selected = selected ? false : true;
          if (this.model.selected === true) {
            properties.add(this.model);
          } else {
            properties.remove(this.model);
          }
          return selectedData.render();
        },
        "keyup": function(e) {
          var $t, val;
          $t = $(e.currentTarget);
          val = $t.find("div").text();
          this.model.set("name", val);
          return selectedData.render();
        }
      }
    });
    properties = new collections.Properties();
    elements = new collections.Elements();
    return classes = new collections.ClassList();
  });

}).call(this);

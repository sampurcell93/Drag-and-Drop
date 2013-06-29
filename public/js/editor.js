// Generated by CoffeeScript 1.6.3
(function() {
  $(document).ready(function() {
    return window.views.ElementEditor = Backbone.View.extend({
      template: $("#element-editor").html(),
      tagName: 'div class="modal"',
      initialize: function() {
        return _.bind(this, "render", "promptSave");
      },
      render: function() {
        this.$el.append(_.template(this.template, this.model.toJSON()));
        return $(document.body).append(this.$el).addClass("active-modal");
      },
      events: {
        "click .close-modal": this.remove,
        "click .save-changes": "bind"
      },
      bind: function() {
        var $classes, apply;
        $classes = this.$el.find("[data-style-generator]");
        apply = {};
        $classes.each(function(i, el) {
          var $el, gen;
          $el = $(el);
          gen = $el.data("style-generator");
          return apply[gen] = $el.val();
        });
        return this.model.set("styles", apply);
      }
    });
  });

}).call(this);
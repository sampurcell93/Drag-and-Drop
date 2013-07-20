$(document).ready ->
    # A view through which users may edit the page layout
    window.views.ElementEditor = Backbone.View.extend {
        template: $("#element-editor").html()
        tagName: 'div class="modal"'
        render: ->
            @$el.append(_.template @template, @model.toJSON())
            $(document.body).append(@$el).addClass("active-modal")
        events: 
            "click .close-modal": @remove
            "click .save-changes": "bind"
        bind: ->
            $classes = @$el.find("[data-style-generator]")
            apply = {}
            $classes.each (i, el)->
                $el = $(el)
                gen = $el.data("style-generator")
                apply[gen] = $el.val()
            @model.set "styles", apply
            # $("body").removeClass("active-modal")
            # @remove()
    }
$ ->
    editors = window.views.editors = {}

    class editors["DefaultEditor"] extends Backbone.View
        columnTemplate: $("#column-picker").html()
        skinTemplate: $("#skins").html()
        initialize: ->
        render: ->
            column_types = ["one", "two", "three", "four", "five", "six"]
            self = @
            modal = window.launchModal(_.template(@skinTemplate, {}) + _.template(@columnTemplate, {}))
            modal.delegate "[data-columns]", "click", ->
                $t = $ this
                cols = $t.data("columns")
                self.model.set({
                    "classes": cols
                    "columns": cols
                })
                _.each column_types, (type) ->
                    self.$el.removeClass("column " + type)
                self.$el.addClass("column " + cols)
            console.log "launch from layouts"
            (@afterRender || ->{})()


    class editors["Button"] extends editors["DefaultEditor"]
        initialize: ->
            super
            # _.bindAll @, "afterRender"
        render: ->
            super
            console.log "button render"
    class editors["accordion"] extends editors["DefaultEditor"]

    # new editors["Button"]().render()
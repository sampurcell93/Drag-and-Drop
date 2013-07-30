$ ->
    editors = window.views.editors = {}

    class editors["DefaultEditor"] extends Backbone.View
        initialize: ->
        render: ->
            console.log "default rendwer"
            modal = window.launchModal("yolo")
            (@afterRender || ->{})()

    class editors["Button"] extends editors["DefaultEditor"]
        initialize: ->
            super
            # _.bindAll @, "afterRender"
        render: ->
            super
            console.log "button render"

    # new editors["Button"]().render()
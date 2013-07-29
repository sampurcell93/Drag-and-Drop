$(document).ready ->

    allLayouts =[
        {
            type: 'Dynamic Layout'
            view: 'dynamicLayout'
        },
        {
            type: 'Dynamic Container'
            view: 'dynamicContainer'
        },
        {
            type: 'Tabs'
            view: 'tabs'
        },
        {
            type: 'Accordion'
            view: 'accordion'
        }
        {
            type: 'Free Form'
            view: 'Freeform'
            columns: '2'
            rows: '2'
        }
    ]
    class window.models.Layout extends window.models.Element


    window.collections.Layouts = Backbone.Collection.extend {
        model: models.Layout          
    } 

    window.views.LayoutList = Backbone.View.extend {
        el: ".layout-types ul"
        template: $("#picker-interface").html()
        initialize: ->
            @controller = @options.controller
            @collection = new collections.Layouts(allLayouts)
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find(@el)
            @el = @$el.get()
            do @render
        render: ->
            $el = @$el
            _.each @collection.models, (layout) ->
                $el.append new views.GenericListItem({model: layout}).render().el
            this
    }        

    class window.views.layout extends window.views.draggableElement
        columnTemplate: $("#column-picker").html()
        # Calls the parent initialize function - mimicry of classical inheritance.
        initialize: -> 
            super
            _.bindAll @, "afterRender"
        afterRender: ->
            @$el.addClass("layout-wrapper")
        events:
            "click .config-panel": (e) ->
                self = @
                modal = window.launchModal(_.template(@columnTemplate, {}))
                modal.delegate "[data-columns]", "click", ->
                    $t = $ this
                    cols = $t.data("columns")
                    console.log cols
                    self.model.set({
                        "classes": cols
                        "columns": cols
                    })
                    self.$el.addClass(cols)
                e.stopPropagation()

    ### Inherited view events are triggered first - so if an indentical event binder is
        applied to a descendant, we can use event.stopPropagation() in order to stop the 
        higher level event from firing. ###

    class window.views["dynamicLayout"] extends window.views["layout"]
        template: $("#dynamic-layout").html()
        initialize: ->
            _.bindAll @, "afterRender"
            super
        afterRender: ->

    class window.views["dynamicContainer"] extends window.views["layout"]
        template: $("#dynamic-container").html()
        initialize: ->
            _.bindAll @, "afterRender"
            super
        afterRender: ->


    class window.views["accordion"] extends window.views["layout"]
        template: $("#accordion-layout").html()
        initialize: ->
            _.bindAll @, "afterRender"
            @listenTo @model.get("child_els"), 'add', (m,c,o) ->
                console.log "added, overwrite"
            super
        afterRender: ->
            if (@model.get("child_els").length)
                @$el.children(".placeholder").remove()

    class window.views["tabs"] extends window.views["layout"]
        template: $("#tab-layout").html()
        settingsTemplate: $("#tab-layout-settings").html()
        initialize: ->
            _.bindAll @, "afterRender"
            super
        events: 
            "click .config-panel": (e) ->
                console.log "yolo"
                modal = window.launchModal(_.template(@settingsTemplate, @model.toJSON()))
                e.stopPropagation()
        afterRender: ->

    class window.views["Freeform"] extends window.views["layout"]
        template: $("#freeform-layout").html()
        configTemplate: $("#freeform-layout-settings").html()
        initialize: ->
            _.bindAll @, "afterRender", "beforeRender"
            super
        afterRender: ->
        beforeRender: ->
            self = @
            if $(".modal").length is 0
                modal = window.launchModal(_.template(@configTemplate, @model.toJSON()))
            else 
                modal = $(".modal").first()
            modal.delegate ".submit", "click", ->
                cols = parseInt($(".set-columns").val())
                rows = parseInt($(".set-rows").val())
                # Default to 2x2
                if !validNumber(cols) then cols = 2
                if !validNumber(rows) then rows = 2
                self.model.set("rows", rows, {silent: true})
                self.model.set("columns", cols, {silent: true})
                self.model.trigger("renderBase")
    class window.views['BlankLayout'] extends window.views["layout"]
        template: $("#blank-layout").html()
        initialize: ->
            _.bindAll @, "afterRender"
            super
        afterRender: ->
            @$el.addClass("blank-layout")
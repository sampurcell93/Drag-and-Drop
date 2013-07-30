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
            type: 'Tabbed Layout'
            view: 'tabs'
        },
        {
            type: 'Accordion Layout'
            view: 'accordion'
        }
        {
            type: 'Free Form Layout'
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
                $el.append new views.OutsideDraggableItem({model: layout}).render().el
            this
    }        

    class window.views.layout extends window.views.draggableElement
        columnTemplate: $("#column-picker").html()
        skinTemplate: $("#skins").html()
        # Calls the parent initialize function - mimicry of classical inheritance.
        initialize: -> 
            super
            _.bindAll @, "afterRender"
        afterRender: ->
            @$el.addClass("layout-wrapper")
        events:
            "click .config-panel": (e) ->
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
            self = @
            @listenTo @model.get("child_els"), {
                "add": @formatNewModel
                "remove": (m,c,o) ->
                    if c.length is 0
                        self.$el.children(".placeholder-text").show()
            }
            super
        defaultContent: {
                name: "New Tab", 
                content: "default"
            }
        events: 
            "click .add-tab": ->
                tabs = @model.get "tabs"
                tabs.push @defaultContent
                @model.set tabs
                @model.trigger("renderBase")
                console.log @model.get("tabs")
            "keyup .tab-list li": (e) ->    
                $t = $(e.currentTarget)
                tabIndex = $t.index()
                tabs = @model.get "tabs"
                tabs[tabIndex].name = $t.html()
                @model.set tabs
        afterRender: ->
            tabs = @model.get "tabs"
            self = @
            _.each tabs, (tab) ->
                model = tab.content.model 
                if tab.content == "default"
                    if tab.content.model instanceof models.Element is true
                        self.$el.children(".tab-content-list").append(new views[model.get("view")])
        formatNewModel: (model, collection, options) ->
            @$el.children(".placeholder-text").hide()
            model.set("view", "tabItem")

    class window.views["tabItem"] extends views["tabs"]
        template: $("#tab-layout-item").html()



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
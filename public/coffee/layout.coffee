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
      
        # Calls the parent initialize function - mimicry of classical inheritance.
        initialize: -> 
            super
            self = @
            @$el.addClass("layout-wrapper")
            @listenTo @model.get("child_els"), "add", (m,c,o)->
                if c? and c.length
                    self.$el.children(".placeholder").hide()
                else 
                    self.$el.children(".placeholder").show()
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
            super
        linkElements: (model) ->
            console.log "linking elements"
            self = @
            model.set("type", "Accordion Header")
            _.each model.get("child_els").models, (child) ->
                child.set("accordion_parent", model)
                if (child.get("child_els").length)
                    self.linkElements(child)
        appendChild: (model) ->
            super
            console.log model
            @linkElements(model)
        afterRender: ->
            if (@model.get("child_els").length)
                @$el.children(".placeholder").remove()

    class window.views["tabItem"] extends views["draggableElement"]
        controls: null 
        events: 
            "keyup": (e) ->    
                $t = $(e.currentTarget)
                @model.set "title", $t.text()
            "click": "showTabContent"                
        initialize: ->
            super
            _.bindAll @, "afterRender"
        appendChild: ->
            super
            console.log "calling layout append"
            @showTabContent()
        afterRender: ->
            @$el.trigger("click").children("h3").first().attr("contentEditable", true).addClass("no-drag")
        showTabContent: ->
            $el = @$el
            siblings = $el.siblings(".builder-element").length + 1
            offset = Math.floor(siblings/7)
            offset = 30 + 50*offset
            console.log $el.children(".children")
            $el.children(".children").css("top", 20 + offset + "px")
            $el.addClass("active-tab").siblings().removeClass("active-tab")
            wrap_height = $el.height() + $el.children(".children").height()
            $el.closest(".tab-layout").css("height", wrap_height + offset + 30 + "px")
            console.log("done")

    class window.views["tabs"] extends window.views["layout"]
        template: $("#tab-layout").html()
        settingsTemplate: $("#tab-layout-settings").html()
        linked_items: ['.tab-list li']
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
        afterRender: ->
            @$el.addClass("tab-layout column six").children(".tab-list").tabs({ active: @options.activeTab || 1 })
            tabs = @model.get "child_els"
            self = @
            _.each tabs.models, (tab) ->
                self.formatNewModel tab
        formatNewModel: (model, collection, options) ->
            model.set("view", "tabItem")
            $el = @$el
            $el.children(".placeholder-text").hide()



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
$(document).ready ->

    adjs = [
        "autumn", "hidden", "bitter", "misty", "silent", "empty", "dry", "dark",
        "summer", "icy", "delicate", "quiet", "white", "cool", "spring", "winter",
        "patient", "twilight", "dawn", "crimson", "wispy", "weathered", "blue",
        "billowing", "broken", "cold", "damp", "falling", "frosty", "green",
        "long", "late", "lingering", "bold", "little", "morning", "muddy", "old",
        "red", "rough", "still", "small", "sparkling", "throbbing", "shy",
        "wandering", "withered", "wild", "black", "young", "holy", "solitary",
        "fragrant", "aged", "snowy", "proud", "floral", "restless", "divine",
        "polished", "ancient", "purple", "lively", "nameless", "protected", 
        "fierce", "snowy", "floating", "serene", "placid", "afternoon", "calm", "cryptic",
        "desolate", "falling", "glacial", "limitless", "murmuring", "pacific", "whispering"
    ]

    nouns = [
        "waterfall", "river", "breeze", "moon", "rain", "wind", "sea", "morning",
        "snow", "lake", "sunset", "pine", "shadow", "leaf", "dawn", "glitter",
        "forest", "hill", "cloud", "meadow", "sun", "glade", "bird", "brook",
        "butterfly", "bush", "dew", "dust", "field", "fire", "flower", "firefly",
        "feather", "grass", "haze", "mountain", "night", "pond", "darkness",
        "snowflake", "silence", "sound", "sky", "shape", "surf", "thunder",
        "violet", "water", "wildflower", "wave", "water", "resonance", "sun",
        "wood", "dream", "cherry", "tree", "fog", "frost", "voice", "paper",
        "frog", "smoke", "star", "savannah", "quarry", "mountainside", "riverbank",
        "canopy", "tree", "monastery", "frost", "shelf", "badlands", "crags", "lowlands",
        "badlands", "woodlands", "eyrie", "beach", "temple"
    ]

    String.prototype.firstUpperCase = ->
        return this.charAt(0).toUpperCase() + this.slice(1)
    randomDict = -> 
        return (adjs[Math.floor(Math.random()*adjs.length)] + "-" + nouns[Math.floor(Math.random()*nouns.length)]).toLowerCase().firstUpperCase() + "-" + Math.floor(Math.random() *10000)


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
            type: 'List Layout'
            view: 'ListLayout'
        }
        {
            type: 'Dynamic Grid'
            view: 'table'
        }
        {
            type: 'Dynamic Repeating Layout'
            view: 'RepeatingLayout'
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
            @model.set("layout", true)
            super
            self = @
            _.bindAll @, "afterRender"
            @$el.addClass("layout-wrapper")
            @listenTo @model.get("child_els"), "add", (m,c,o)->
                if c? and c.length
                    self.$el.children(".placeholder").hide()
                else 
                    self.$el.children(".placeholder").show()
            _.extend @events, {
                "click .ungroup-fields": ->
                    model    = @model
                    # Get position of layout
                    position = model.collection.indexOf(model)
                    children = model.get("child_els")
                    parent   = model.collection
                    to_remove= [] 
                    for child, i in children.models
                        child['layout-item']= false
                        # Unlink each model from the collection
                        child.collection = null
                        # Simply adding at position would insert elements in reverse order
                        parent.add child, {at: position + i }
                    # Remove each model from group collection
                    children.reset()
                    # Destroy the layout/group
                    model.destroy()
                }
        afterRender: ->
            if @model.get("child_els").length > 0
                @$el.children(".placeholder").hide()
    ### Inherited view events are triggered first - so if an indentical event binder is
        applied to a descendant, we can use event.stopPropagation() in order to stop the 
        higher level event from firing. ###

    class views["table"] extends views["layout"]
        tagName: 'table class="builder-element column six"'
        template: $("#table-layout").html()
        initialize: ->
            super
            self = @
            @model.get("child_els").on "add", (model, collection, options) ->
                # This only accepts properties for table structure
                if model.get("type") != "Property"
                    # Stop the element from being added
                    collection.remove model
                    # Then add it one level up.
                    self.model.collection.add model
                else
                    model.set("view", "TableCell")
                    console.log self.$el.find(".dummy")
                    self.$el.find(".dummy").first().append(self.dummyData())
        dummyData: ->
            cols = @model.get("child_els").length
            rows = 5
            cell_template = "<td><%= word %></td>"
            dummy = ""
            for row in [0...rows]
                if row > 0
                    dummy += "<tr>"
                for col in [0...cols]
                    dummy += _.template cell_template, {word: randomDict()}
                if row > 0
                    dummy += "</tr>"
            dummy


    class window.views["dynamicLayout"] extends window.views["layout"]
        configTemplate: $("#dynamic-layout-setup").html()
        template: $("#dynamic-layout").html()
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


    class window.views["dynamicContainer"] extends window.views["layout"]
        template: $("#dynamic-container").html()
        initialize: ->
            _.bindAll @, "afterRender"
            super
        afterRender: ->

    #  Layout for tab structure and all child items
    class window.views["tabItem"] extends views["draggableElement"] 
        events: 
            "keyup h3:first-child": (e) ->    
                $t = $(e.currentTarget)
                console.log $t
                @model.set "title", $t.text()
            "click": "showTabContent"                
        tabOffset: ->
            len = @model.collection.length
            $el = @$el
            num_per_row = 0
            column_types = ["two", "three", "four", "five", "six"]
            _.each column_types, (num,i) ->
                if $el.closest(".tab-layout").hasClass("column " + num)
                    num_per_row = i + 2
            10 + 50*(len/num_per_row)
        initialize: ->
            super
            self = @
            console.log "making new tab item"
            _.bindAll @, "afterRender", "showTabContent"
            @model.get("child_els").on({
                "remove": @showTabContent
            })
        appendChild: (model) ->
            super
            @$el.children("h3").first().trigger("click")
        afterRender: ->
            @$el.css("display","inline-block !important")
            .children("h3").first().attr("contentEditable", true).addClass("no-drag").trigger("click")
        showTabContent: ->
            console.log "showTabContent"
            # Settign height of parent container and showing the tab content
            $el = @$el
            offset = @tabOffset()
            console.log offset
            $el.children(".children").css({"top": 20 + offset + "px"})
            $el.addClass("active-tab").siblings().removeClass("active-tab")
            wrap_height = $el.height() + $el.children(".children").height()
            console.log wrap_height
            $el.closest(".tab-layout").css("height", wrap_height + offset + 12 + "px")
            console.log("done", $el.height() + $el.children(".children").height())
            @$el.children(".config-menu-wrap").css({"top": (offset - 10) + "px", "right": "26px"})

    class window.views["tabs"] extends window.views["layout"]
        template: $("#tab-layout").html()
        itemName: 'tabItem'
        tagName: 'div class="builder-element tab-layout column six"'
        initialize: ->
            @model.set("type", "Tab Layout")
            _.bindAll @, "afterRender"
            self = @
            @listenTo @model.get("child_els"), {
                "remove": (m,c,o) ->
                    if c.length is 0
                        self.$el.children(".placeholder-text").show()
            }
            @model.get("child_els").on "add", ->
                cc "addd ON"
                self.$el.children(".placeholder-text").hide()
            super
        afterRender: ->
            cc "tabs after rendering"
            tabs = @model.get "child_els"
            self = @
            console.log tabs.models
            _.each tabs.models, (tab) ->
                self.formatNewModel tab
        formatNewModel: (model, collection, options) ->
            model.set("view", "tabItem")
            @$el.children(".placeholder-text").hide()

    class views["ListLayout"] extends views['layout']
        initialize: ->
            super
            @model.set("type", "List Layout")
            _.bindAll(@, "afterRender")
        afterRender: ->
            @$el.addClass("list-layout")

    class window.views['BlankLayout'] extends window.views["layout"]
        template: $("#blank-layout").html()
        initialize: ->
            _.bindAll @, "afterRender"
            super
        afterRender: ->
            @$el.addClass("blank-layout")

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
            view: 'DynamicLayout'
        },
        # {
        #     type: 'Dynamic Container'
        #     view: 'dynamicContainer'
        # },
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
        template: $("#picker-interface").html()
        initialize: ->
            @controller = @options.controller
            @collection = new collections.Layouts(allLayouts)
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find(".layout-types ul")
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
            @model.set("layout", true, {no_history: true })
            super
            self = @
            _.bindAll @, "afterRender", "bindDrop", "appendChild"
            @$el.addClass("layout-wrapper")
            @listenTo @model.get("child_els"), {
                "add": (m,c,o)->
                    if c? and c.length
                        self.$el.children(".placeholder").hide()
                "remove": (m, c, o) ->
                    if c? and !c.length
                        self.$el.children(".placeholder").show()
                }
            @listenTo @model, {
                "change:presetlayout": (model,attr,opts)->
                    self.formPresetLayout(attr)
            }
            _.extend @events, {
                "click .ungroup-fields": ->
                    model    = @model
                    # Get position of layout
                    position = model.collection.indexOf(model)
                    children = model.get("child_els")
                    parent   = model.collection
                    for child, i in children.models
                        child['selected'] = false
                        # Unlink each model from the collection
                        child.collection = null
                        # Simply adding at position would insert elements in reverse order
                        parent.add child, {at: position + i }
                    # Remove each model from group collection
                    children.reset()
                    # Destroy the layout/group
                    model.destroy()
                "click .paste-element": ->
                    copy = window.copiedModel
                    if copy? then @model.blend copy, opname: 'paste'
                }
            do @bindDrop
            @
        appendChild: ( child , opts ) ->
            # We choose a view to render based on the model's specification, 
            # or default to a standard draggable.
            $el = @$el.children(".children")
            # For table layouts, sometimes things are wrapped in a tbody
            if $el.length == 0 then $el = $el.find(".children").first()
            if child['layout-item'] is true then $el.addClass "selected-element"
            view = child.get("view") || "draggableElement"
            draggable = $(new views[view]({model: child, index: window.currIndex, parent: @$el}).render().el).addClass("builder-child")
            if child.get("inFlow") is false then draggable.hide()
            if (opts? and !opts.at?)
                $el.append(draggable)
            else 
                builderChildren = $el.children ".builder-element"
                if builderChildren.eq(opts.at).length 
                    builderChildren.eq(opts.at).before draggable
                else $el.append draggable
            if allSections.at(currIndex).get("builder")?
                allSections.at(currIndex).get("builder").removeExtraPlaceholders()
        bindDrop: ->
            that = this
            @$el.droppable {
              greedy:true                                          # intercepts events from parent
              tolerance: 'pointer'                                 # only the location of the mouse determines drop zone.
              accept: '.builder-element, .outside-draggables li, .property'
              over: (e) ->
                if $(document.body).hasClass("active-modal") then return false
                $(e.target).addClass("over")
              out: (e)->
                $(e.target).removeClass("over").parents().removeClass("over")
              drop: (e,ui) ->
                $(e.target).removeClass("over").parents().removeClass("over")
                if $(document.body).hasClass("active-modal") then return false
                draggingModel = window.currentDraggingModel
                if typeof draggingModel is "undefined" or !draggingModel? then return false
                else if draggingModel is that.model then return false

                if !$.isArray(draggingModel) and draggingModel.get("inFlow") is false
                    draggingModel.set("inFlow", true)
                    return
                sect_interface = allSections.at(that.index || currIndex)
                section = sect_interface.get("currentSection")
                builder = sect_interface.get("builder")
                model = that.model
                opts = opname: $(ui.helper).data("opname") || "Added"
                # if the dragged element is a direct child of its new parent, do nothing
                unless draggingModel.collection is model.get("child_els")
                 if model.blend(draggingModel, opts) is true
                    $(ui.helper).remove()
                    # Lets the drag element know that it was a success
                    ui.draggable.data('dropped', true)
                    delete window.currentDraggingModel
                    window.currentDraggingModel = null
                e.stopPropagation()
                e.stopImmediatePropagation()
                true
            }
        afterRender: ->
            if @model.get("child_els").length > 0
                @$el.children(".placeholder").hide()
        unbindLayout: ->
            # Get all direct children
            layout_items = @model.get("child_els")
            self = @
            temp = []
            # Iterate each direct child
            _.each layout_items.models, (item) ->
                # If this is a layout component, flag it for removal
                if item.layoutItem is true 
                    temp.push item
                # Get all children
                children = item.get "child_els"
                # Remove each model from the layout item and put it in the layout
                _.each children.models, (child) ->
                    self.model.blend child, no_history: true
            # Finally, destroy the layout items - can't do this in _.each 
            # because it will break the function by changing the array
            _.each temp, (dest) ->
                dest.destroy no_history: true
        barLayout: (sidebar, content) ->
            model    = @model
            @model.set "title", "Bar Layout"
            sidebar  = new window.models.Element(sidebar)
            content  = new window.models.Element(content)
            elChildren = @model.get("child_els")
            # get the first child
            first    = elChildren.at 0
            # and the rest
            rest = elChildren.slice 1
            sidebar.layoutItem = content.layoutItem = true
            none = no_history: true
            if content.view == "RightBar"
                model.blend [content, sidebar], none
                # blend existing models into new layout
                sidebar.blend first, none
                content.blend rest, none
            else
                model.blend [sidebar, content], no_history: true, opname: 'columnize'
                # blend existing models into new layout
                sidebar.blend rest, none
                content.blend first, none
        formPresetLayout: (layout) ->
            if !layout? then return false
            # Make sure we're not adding layouts to each other - return the layout to a blank state
            @unbindLayout()
            # Apply the new logic
            @layouts[layout](@)
        layouts: {
            "right-bar": (self) ->
               self.barLayout({view: 'RightBar', type: "Dynamic Layout", title: 'Right Sidebar'},{view: 'LeftContent', type: "Dynamic Layout", title: 'Left Content'})
            "left-bar": (self) ->
               self.barLayout({view: 'LeftBar', type: "Dynamic Layout", title: 'Left Sidebar'},{view: 'RightContent',type: "Dynamic Layout", title: 'Right Content'})
            "header-left-bar": (self) ->
                layout = new models.Element({layout: true, type: 'Dynamic Layout', view: "DynamicLayout", title: 'Header'})
                layout.layoutItem = true
                self.barLayout({view: 'LeftBar', type: "Dynamic Layout", title: 'Left Sidebar'},{view: 'RightContent', type: "Dynamic Layout", title: 'Right Content'})
                self.model.blend layout, at: 0
            "header-right-bar": (self) ->
                layout = new models.Element({layout: true, type: 'Dynamic Layout', view: "DynamicLayout", title: 'Header'})
                layout.layoutItem = true
                self.barLayout({view: 'RightBar',type: "Dynamic Layout", title: 'Right Sidebar'},{view: 'LeftContent',type: "Dynamic Layout", title: 'Left Content Sidebar'})
                self.model.blend layout, at: 0
            "header-split": (self) ->
                layout = new models.Element({layout: true, type: 'Dynamic Layout', view: "DynamicLayout", title: 'Header'})
                layout.layoutItem = true
                half   = {view: 'HalfContent', type: "Dynamic Layout", title: 'Half Content'}
                self.barLayout(half,half)
                self.model.blend layout, at: 0
        }
    ### Inherited view events are triggered first - so if an indentical event binder is
        applied to a descendant, we can use event.stopPropagation() in order to stop the 
        higher level event from firing. ###

    class window.views['BuilderWrapper'] extends window.views.layout
        controls: null
        contextMenu: $("#placeholder-context").html()
        className: 'builder-scaffold'
        template: $("#builder-wrap").html()
        initialize: ->
            super
            self = @
            _.bindAll(@, "afterRender")
            @model.on "render": ->
                self.render(true)
        # We don't want this to be resizable
        bindResize: ->
        appendChild: ->
            super
            @$el.children(".placeholder").remove()
        bindDrag: ->
        afterRender: ->
            that = @
            @$el.selectable {
                filter: '.builder-element:not(.builder-scaffold)'
                tolerance: 'touch'
                cancel: ".config-menu-wrap, input, .title-setter, textarea, .no-drag, .context-menu"
                stop: (e)->
                    if (e.shiftKey is true)
                        that.blankLayout()
                selecting: (e,ui) ->
                    $(ui.selecting). trigger "select"
                unselecting: (e,ui) ->
                    if (e.shiftKey is true) then return 
                    $item = $(ui.unselecting)
                    $item.trigger "deselect"
            }

    class views["table"] extends views["layout"]
        tagName: 'table'
        className: 'builder-element column six'
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


    class window.views["DynamicLayout"] extends window.views["layout"]
        configTemplate: $("#dynamic-layout-setup").html()
        template: $("#dynamic-layout").html()


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
            @model.set("type", "Tab Layout", {silent: true})
            _.bindAll @, "afterRender"
            self = @
            @listenTo @model.get("child_els"), {
                "remove": (m,c,o) ->
                    if c.length is 0
                        self.$el.children(".placeholder-text").show()
            }
            @model.get("child_els").on "add", ->
                self.$el.children(".placeholder-text").hide()
            super
        afterRender: ->
            cc "tabs after rendering"
            tabs = @model.get "child_els"
            self = @
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

    class views["RepeatingLayout"] extends views['layout']


    class views["LayoutItem"] extends views['layout']
        bindDrag: ->
        controls: null
        initialize: (opts) ->
            super
            if opts? and opts.placeholder?
                @placeholder = opts.placeholder
    # Layout component views
    class views['RightBar'] extends window.views['LayoutItem']
        className: 'builder-element sidebar-wrapper fr'
        template: "<p class='placeholder'>Right Bar</p>"

    class views['LeftContent'] extends window.views['LayoutItem']
        className: 'builder-element content-wrapper fl'
        template: "<p class='placeholder'>Left Content</p>"

    class views['LeftBar'] extends window.views['LayoutItem']
        className: 'builder-element sidebar-wrapper fl'
        template: "<p class='placeholder'>Left Bar</p>"

    class views['RightContent'] extends window.views['LayoutItem']
        className: 'builder-element content-wrapper fr'
        template: "<p class='placeholder'>Right Content</p>"
    class views['HalfContent'] extends window.views['LayoutItem']
        className: 'builder-element half-content fl'
        template: "<p class='placeholder'>Half Content</p>"
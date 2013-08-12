$(document).ready ->
    ### 
        MUST be bound to the window, so as not to leak into 
        global namespace and still have access to other scripts 
    ###

    window.globals =
         setPlaceholders: (draggable, collection) ->
            draggable
            .before(before = new views.droppablePlaceholder({collection: collection}).render())
            .after(after = new views.droppablePlaceholder({collection: collection}).render())
            if before.prev().css("display") == "inline-block"
                before.css("height", before.prev().height() + "px")
            # extra = new window.views.droppablePlaceholder({collection: collection}).render()
            # if (draggable.index() is 0 and !draggable.hasClass("builder-child"))
            #     draggable.before(extra)
            # else if (draggable.hasClass("builder-child") and draggable.prev(".builder-child").length is 0)
            #     draggable.before(extra)


    class window.models.Element extends Backbone.Model
        initialize: ->
            self = @
            @on {
                "change:view": (model,view,opts) ->
                    collection = model.collection
                    index = collection.indexOf(model)
                    console.log collection
                    if collection? and typeof collection != "undefined"
                        collection.remove model, {no_history: true}
                        collection.add model, {at: index, no_history: true }
            }
        defaults: ->
            child_els = new collections.Elements()
            child_els.model = @
            {
                "child_els": child_els
                "inFlow": true
                classes: []
                styles: {
                    background: null
                    border: {
                        left: {}
                        right: {}
                        top: {}
                        bottom: {}
                    }
                    'box-shadow': null
                    color: null
                    font: {
                        size: null
                        weight: null
                    }
                    opacity: null
                }
            }
        url: ->
            url = "/section/"
            url += if @id? then @id else ""
            url
        # Recursively makes models out of the standard javascript objects returned by ajax
        modelify: ->
            self = @
            temp = new collections.Elements()
            if !@get("child_els")? then return false
            clone = @get("child_els").clone()
        # JSON returns as a single model whose submodels are standard json objects, not backbone models.
        # MODELIFY each standard json object, and its children, recursively.
        parse: (response) ->
            response.child_els = @modelify(response.child_els)
            response
        blend: (putIn, at) ->
            if !putIn? then return false
            # If put in is a collection
            if $.isArray(putIn) is true and putIn.length > 1
                if putIn.indexOf(@) != -1
                    alert("you may not drag shit into itself. DIVIDE BY ZERO")
                    return false
                # Remove each model from its collection so that events are triggered
                _.each putIn, (model) ->
                    model.collection.remove model, {no_history: true}
            # Remove the model from its current collection, if there is such.
            else if putIn.collection?
                putIn.collection.remove putIn, {no_history: true}
            # Get all current child elements, add the dropped element(s)
            # and put the collection back in
            children = @get "child_els"
            # We don't need to validate "at" because backbone will simply append if "at" is undefined
            children.add(putIn, {at: at})
            @set "child_els", children
            true

    window.collections.Elements = Backbone.Collection.extend {
        model: models.Element
        url: '/section/'
        blend: (putIn, at) ->
            if !putIn? then return false
            if $.isArray(putIn) is true and putIn.length > 1
                 _.each putIn, (model) ->
                    model.collection.remove model, {no_history: true}
            else if putIn.collection?
                putIn.collection.remove putIn, {no_history: true}
            @add putIn, {at: at}
            true
         # Takes in a new index, an origin index, and an optional collection
        # When collection is ommitted, the collection uses this.collection
        reorder: (newIndex, originalIndex, collection, options) ->
            if newIndex is originalIndex then return this
            # Get the original index of the moved item, and save the item
            collection = collection || @
            temp = collection.at(originalIndex)
            # Remove it from the collection
            collection.remove(temp, {organizer: {itemRender: false, render: false},  no_history: true})
            # Reinsert it at its new index
            collection.add(temp, {at: newIndex, organizer: {itemRender: false, render: false}})
            this
        # Returns an array of all models that match the property, recursively. Defaults to layout item search
        gather: (prop) ->
            # Normally would use _.filter() here but we are looking for model properties - not their .get()/.set() attributes
            prop = prop || "layout-item"
            models = []
            self = @
            # check each model in collection
            _.each @models, (model) -> 
            # If the model is selected, push onto array
                if (model[prop] is true)
                    models.push model
                # Call recursively on each child collection
                models = models.concat(model.get("child_els").gather())
            models
        clone: ->
            copy = new collections.Elements()
            _.each @models, (element) ->
                deep_copy_model = element.clone()
                children = deep_copy_model.get("child_els")
                deep_copy_model.set("child_els", children.clone(), {no_history: true})
                copy.add new models.Element(deep_copy_model.toJSON()), {no_history: true}
            copy
        compare: (collection) ->
            self = @
            comparison = true
            _.each collection.models, (model, i) ->
                if JSON.stringify(model.attributes) != JSON.stringify(self.at(i).attributes)
                    console.log  JSON.stringify(model.attributes), JSON.stringify(self.at(i).attributes)
                    cc "faseeeeee"
                    comparison = false
            comparison
    }

    class window.views.droppablePlaceholder extends Backbone.View
        events:
            "remove": ->
                do @remove
        render: ->
            self = @
            ghostFragment = $("<div/>").addClass("droppable-placeholder").html("<div class='make-bigger'></div>")
            ghostFragment.droppable
                accept: ".builder-element, .outside-draggables li, .property"
                greedy: true
                tolerance: 'pointer' 
                over: (e, ui) ->
                    if $(document.body).hasClass("active-modal") then return false
                    $(e.target).css("opacity", 1)
                out: (e, ui) ->
                    $(e.target).css("opacity", 0)
                drop: (e,ui) ->
                    $(".over").removeClass("over")
                    if $(document.body).hasClass("active-modal") then return false
                    dropZone = $(e.target)
                    if (dropZone.closest(".builder-element").length)
                        insertAt = dropZone.closest(".builder-element").children(".children").children(".builder-element").index(dropZone.prev())
                    else   
                        insertAt = dropZone.closest("section").children(".children").children(".builder-element").index(dropZone.prev())
                    # if (ui.draggable.index() > dropZone.index() or ui.draggable.hasClass("generic-item"))
                    insertAt += 1
                    curr = window.currentDraggingModel
                    parent = self.collection.model 
                    if typeof parent is "function" or !parent? then parent = self.collection
                    parent.blend(curr, insertAt)
                    $(e.target).css("opacity", 0)
                    delete window.currentDraggingModel
                    window.currentDraggingModel = null
                    ui.helper.fadeOut(300)


    ### A configurable element bound to a property or page element
        Draggable, droppable, nestable. ###
    class window.views.draggableElement extends Backbone.View
        template: $("#draggable-element").html()
        controls: $("#drag-controls").html()
        contextMenu: $("#context-menu-default").html()
        tagName: 'div'
        className: 'builder-element'
        modelListeners: {}
        initialize: ->
            _.bindAll(this, "render", "bindDrop", "bindDrag","appendChild","bindListeners")
            @on "bindListeners", @bindListeners
            # Bind the drag event to the el
            do @bindDrop
            # Bind the drop event to the el
            do @bindDrag
            # Bind all model listeners
            do @bindListeners
        bindListeners: ->
            self = @
            # Unbind previous listeners
            @stopListening()
            @listenTo @model.get("child_els"),
            {   'add': (m,c,o) ->
                    unless (typeof self.itemName == "undefined")
                        console.log self.itemName
                        m.set("view", self.itemName)
                    self.appendChild(m,o)
            }

            @modelListeners = _.extend({}, @modelListeners, { 
                "change:classes": ->
                    @render(false)
                "change:child_els": ->
                    self.bindListeners()
                    self.render()
                "change:inFlow": ( model ) ->
                    if model.get("inFlow") is true
                         self.$el.slideDown("fast").
                         next(".droppable-placeholder").slideDown("fast").
                         prev(".droppable-placeholder").slideDown("fast")
                    else 
                        self.$el.slideUp("fast").
                        next(".droppable-placeholder").slideUp("fast").
                        prev(".droppable-placeholder").slideUp("fast")
                "remove": ->
                    self.$el.next(".droppable-placeholder").remove()
                    self.remove()
                "sorting": ->
                    self.$el.addClass("selected-element")
                "end-sorting": ->
                    if (self.$el.hasClass("ui-selected") is false)
                        self.$el.removeClass("selected-element")
                "renderBase": ->
                    self.render(false)
                "render": ->
                    self.render(true)
            })
            # Allow class descendants to bind listeners
            @listenTo @model, @modelListeners
        render: (do_children) ->
            if typeof do_children is "undefined" then do_children = true
            # For inherited views that don't want to overwrite render entirely, we have 
            # custom methods to accompany it.
            (@beforeRender || -> {})()
            that = @
            model = @model
            model["layout-item"] = false
            children = model.get "child_els" 
            $el =  @$el
            $el.html(_.template @template, model.toJSON())
            if @controls? then $el.append(_.template @controls, model.toJSON())
            if $el.children(".children").length is 0
                    $el.append("<ul class='children'></ul>")
            if children? and do_children is true
                if children.length > 0 then @$el.children(".placeholder").hide()
                _.each children.models , (el) ->
                    that.appendChild el, {}
            @applyClasses()
            @checkPlaceholder()
            (@afterRender || -> 
                $el.hide().fadeIn(325)
            )()
            @
        appendChild: ( child , opts ) ->
            console.log "appending child!"
            # We choose a view to render based on the model's specification, 
            # or default to a standard draggable.
            $el = @$el.children(".children")
            # For table layouts, sometimes things are wrapped in a tbody
            if $el.length == 0 then $el = $el.find(".children").first()
            if child['layout-element'] is true then $el.addClass("selected-element")
            view = child.get("view") || "draggableElement"
            if child.get("inFlow") is true
                i = currIndex
                draggable = $(new views[view]({model: child, index: i}).render().el).addClass("builder-child")
                if (opts? and !opts.at?)
                    $el.append(draggable)
                else 
                    console.log opts.at
                    builderChildren = $el.children(".builder-element")
                    if builderChildren.eq(opts.at).length 
                        builderChildren.eq(opts.at).before(draggable)
                    else $el.append(draggable)
                globals.setPlaceholders($(draggable), @model.get("child_els"))
                allSections.at(currIndex).get("builder").removeExtraPlaceholders()
        bindDrag: ->
            that = this
            # Set the element to be draggable.
            @$el.draggable
                cancel: ".no-drag, .context-menu"
                revert: true
                scrollSensitivity: 100
                helper: ->
                    # Get all selecged elements
                    selected = that.$el.closest("section").find(".ui-selected, .selected-element")
                    self = $(this)
                    if !self.hasClass("selected-element") then return self
                    console.log "helper"
                    # Make a wrapper for all elements
                    wrap = $("<div />").html(self.clone()).css("width", "100%")
                    # Append each selected item to the wrapper so the user can see what they drag
                    selected.each -> 
                        console.log "eachin"
                        # Do not reappend the direct dragged item - it need not be selected, per se
                        # but may still be the subject of a drag. Do not reappend children.
                        unless self.is(this)
                            if $(this).index() > self.index()
                                wrap.append $(this).clone()
                            else wrap.prepend $(this).clone()
                    wrap.addClass("selected-element")
                cursor: "move"
                start: (e, ui) ->
                    if e.shiftKey is true then return false
                    sect_interface = allSections.at(currIndex)
                    section = sect_interface.get("currentSection")
                    ui.helper.addClass("dragging")
                    if (ui.helper.hasClass("selected-element"))
                        allDraggingModels = section.gather()
                    else allDraggingModels = []
                    console.log allDraggingModels.length
                    # When a drag starts, give the builder the model (or collection of such) so it can render on drop
                    if allDraggingModels.length > 1
                        window.currentDraggingModel = allDraggingModels
                    else window.currentDraggingModel = that.model
                stop: (e, ui) ->
                    $(ui.helper).removeClass("dragging")
        bindDrop: ->
        removeFromFlow: (e) ->        #  When they click the "X" in the config - remove the el from the builder
            that = @
            destroy = ->
                that.model.set("inFlow", false)
            if e.type == "flowRemoveViaDrag"
                @$el.toggle("clip",  300, destroy)
            else do destroy

            e.stopPropagation()
            e.stopImmediatePropagation()  
        checkPlaceholder: ->
            # parent = @$el.prev()
            # console.log @$el, parent, parent.hasClass("layout-wrapper")

        applyClasses: ->
            $el = @$el
            console.log @model.get "classes"
            # "class" is a reserved keyword. style instead
            _.each @model.get("classes"), (style) ->
                $el.addClass(style)

        # Grabs all selected elements and groupes them into a barebones layout
        blankLayout: (e) ->
            collection = allSections.at(currIndex).get("currentSection")
            selected = collection.gather()
            if selected.length is 0 or selected.length is 1 then return
            layoutIndex = collection.indexOf(selected[0])
            collection.add(layout = new models.Element({view: 'BlankLayout', type: 'Blank Layout'}), {at: layoutIndex, no_history: true})
            _.each selected , (model) ->
                if model.collection?
                    model.collection.remove model, {no_history: true}
                layout.get("child_els").add model
            if e? then e.stopPropagation()
            @
        bindContextMenu:  (e) ->
            if !@contextMenu? then return true
            else if e.shiftKey is true
                @unbindContextMenu(e)
                return true
            @unbindContextMenu(e)
            e.preventDefault()
            $el = @$el
            pageX = e.pageX - $el.offset().left
            pageY = e.pageY - $el.offset().top
            # Remove all other right click menus
            $("<ul />").html(_.template(@contextMenu, {})).
            addClass("context-menu").
            css({"top":pageY + "px", "left": pageX + "px"}).
            appendTo(@$el)
            e.stopPropagation()
            false
        unbindContextMenu: (e) ->
            menu = $(".context-menu") 
            if e? and $(e.currentTarget).hasClass("context-menu") then return false
            else if !menu.length then return false
            menu.remove()
        # Default events for any draggable - basically configuration settings.
        events: 
            # for debugging
            "dblclick": (e) ->
                console.log @model
                e.stopPropagation()
            # for right click functionality users expect
            "contextmenu": "bindContextMenu"
            "click .context-menu": (e) ->
                # Stop the context menu from closing
                e.stopPropagation()
            "click .group-elements": "blankLayout"
            "click .destroy-element": ->
                @model.destroy()
            "click": (e) ->
                @unbindContextMenu(e)
                @$el.find(".dropdown").hide()
                if e.shiftKey is true
                    layout = @model["layout-item"]
                    if (layout is false or typeof layout is "undefined")
                        @$el.trigger("select")
                    else 
                        @$el.trigger("deselect")
                e.stopPropagation()
                e.stopImmediatePropagation()
            "click .set-options": (e) ->
                @unbindContextMenu(e)
                $t = $(e.currentTarget)
                dropdown = $t.children(".dropdown")
                $(".dropdown").not(dropdown).hide()
                dropdown.fadeToggle(100);
                e.stopPropagation()
            "click .set-options li": (e) ->
                @unbindContextMenu(e)
                # So as to stop the parent list from closing
                e.preventDefault()
                e.stopPropagation()          
            "click .view-attrs": ->
                new views.toolbelt.Actives({model: @model}).render()
            "click .remove-from-flow": (e) ->
                e.stopPropagation()
                # e.stopImmediatePropagation()
                @removeFromFlow(e)
            "flowRemoveViaDrag": "removeFromFlow" 
            "click .config-panel": (e) ->            
                defaultEditor = if @model.get("layout") == true then "BaseLayoutEditor" else "BaseEditor"
                editor = views.editors[@edit_view || @model.get("view") || defaultEditor]
                if editor? then editor = new editor({model: @model, link_el: @el}).render()
                else editor = new views.editors[defaultEditor]({model: @model, link_el: @el}).render()
                $(editor.el).launchModal()
            "select" : (e) ->
                # Setting this property will not affect rendering immediately, so make it silent. 
                @model["layout-item"] = true
                @$el.addClass("selected-element")
                e.stopPropagation()
                e.stopImmediatePropagation()
            "deselect": (e) ->
                @model["layout-item"] = false
                @$el.removeClass("selected-element")
                e.stopPropagation()
                e.stopImmediatePropagation()
            "sorting": ->
                @$el.addClass("active-sorting")
            "end-sorting": ->
                @$el.removeClass("active-sorting")

    # The builder is less of a listview and more of a simple controller whose render only appends a single droppable wrapper
    # whose model is not included in the collection. This reduces redundancy.
    window.views.SectionBuilder = Backbone.View.extend {
        rendered: false
        initialize: ->
            @controller = @options.controller
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find("section")
            @collection = @options.collection
            @render()
        render: (children) ->
            unless @rendered is true
                @rendered = true
                $el = @$el
                that = this
                @append @scaffold = new models.Element({view: "BuilderWrapper"})
        append: (element, opts) ->
            view = element.get("view")
            element.set("child_els", @collection)
            @$el.append draggable = $(new views[view]({model: element}).render().el)
            @removeExtraPlaceholders()
            draggable
        removeExtraPlaceholders: ->
            @$el.find(".droppable-placeholder").each ->
                $t = $(this)
                flag = 0
                if $t.next().hasClass("droppable-placeholder")
                    $t.next().remove()  
                if $t.prev().hasClass("droppable-placeholder")
                    $t.prev().remove()
                if !$t.next().hasClass("builder-element")
                    flag += 1
                if !$t.prev().hasClass("builder-element")
                    flag += 1
                if flag is 2 then $t.remove()
    }
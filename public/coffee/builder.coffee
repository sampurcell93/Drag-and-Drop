$(document).ready ->
    ### 
        MUST be bound to the window, so as not to leak into 
        global namespace and still have access to other scripts 
    ###

    window.globals =
         setPlaceholders: (draggable, collection) ->
            console.log "next one ", draggable.next(".droppable-placeholder").length, " prev one", draggable.prev(".droppable-placeholder").length
            draggable.before(new window.views.droppablePlaceholder({collection: collection}).render())
            draggable.after(new window.views.droppablePlaceholder({collection: collection}).render())
            # extra = new window.views.droppablePlaceholder({collection: collection}).render()
            # if (draggable.index() is 0 and !draggable.hasClass("builder-child"))
            #     draggable.before(extra)
            # else if (draggable.hasClass("builder-child") and draggable.prev(".builder-child").length is 0)
            #     draggable.before(extra)


    window.models.Element = Backbone.Model.extend {
        defaults: ->
            "child_els": new collections.Elements()
            "inFlow": true
        url: ->
            url = "/section/"
            url += if @id? then @id else ""
            url
        # Recursively makes models out of the standard javascript objects returned by ajax
        modelify: (child_els) ->
            self = @
            temp = new collections.Elements()
            _.each child_els, (model) ->
                temp.add tempModel = new models.Element(model)
                tempModel.set "child_els", self.modelify(tempModel.get "child_els" )
            temp
        # JSON returns as a single model whose submodels are standard json objects, not backbone models.
        # MODELIFY each standard json object, and its children, recursively.
        parse: (response) ->
            response.child_els = @modelify(response.child_els)
            response
        blendModels: (putIn) ->
            # If put in is a collection
            if $.isArray(putIn) is true and putIn.length > 1
                if putIn.indexOf(@) != -1
                    alert("you may not drag shit into itself. DIVIDE BY ZERO")
                    return false
                # Remove each model from its collection so that events are triggered
                _.each putIn, (model) ->
                    model.collection.remove model
            # Remove the model from its current collection, if there is such.
            else if putIn.collection?
                putIn.collection.remove putIn
            # Get all current child elements, add the dropped element(s)
            # and put the collection back in
            children = @get "child_els"
            if children?
                @set "child_els", children.add(putIn)
            true
        updateListItems: (text, index) ->
             if (@get("type") == "Numbered List" || @get("type") == "Bulleted List")
                listItems = @get("listItems")
                if listItems?
                    listItems[index] = {}
                    listItems[index].text = text
                else listItems.splice(index,0, {text: text})
                @set("listItems", listItems)
    }


    window.collections.Elements = Backbone.Collection.extend {
        model: models.Element
        url: '/section/'
         # Takes in a new index, an origin index, and an optional collection
        # When collection is ommitted, the collection uses this.collection
        reorder: (newIndex, originalIndex, collection, options) ->
            console.log originalIndex, newIndex
            # Get the original index of the moved item, and save the item
            collection = collection || @
            temp = collection.at(originalIndex)
            # Remove it from the collection
            collection.remove(temp, {organizer: {itemRender: false}})
            # Reinsert it at its new index
            collection.add(temp, {at: newIndex, organizer: {itemRender: false, render: false}})
            this
        # Returns an array of all models that match the property, recursively. Defaults to layout item search
        gather: (prop) ->
            # Normally would use _.find() here but we are looking for model properties - not their .get()/.set() attributes
            prop = prop || "layout-item"
            models = []
            self = @
            _.each @models, (model) -> 
                if (model[prop] is true)
                    models.push model
                models.concat(model.get("child_els").gather())
            models
    }

    class window.views.droppablePlaceholder extends Backbone.View
        render: ->
            self = @
            ghostFragment = $("<div/>").addClass("droppable-placeholder").text("")
            ghostFragment.droppable
                accept: ".builder-element, .generic-elements li"
                greedy: true
                tolerance: 'pointer' 
                over: (e, ui) ->
                    $(e.target).css("opacity", 1)
                out: (e, ui) ->
                    $(e.target).css("opacity", 0)
                drop: (e,ui) ->
                    $(".over").removeClass("over")
                    dropZone = $(e.target)
                    if (dropZone.closest(".builder-element").length)
                        insertAt = dropZone.closest(".builder-element").children(".builder-element").index(dropZone.prev())
                    else 
                        insertAt = dropZone.closest("section").children(".builder-element").index(dropZone.prev())
                    insertAt += 1
                    curr = window.currentDraggingModel
                    c = curr.collection
                    # If the model is in a collection, and it's not the same one as the builder,
                    # IE not top level
                    if c? and c != self.collection
                        c.remove curr
                        curr.set "inFlow", true
                    self.collection.add curr, {at: insertAt}
                    delete window.currentDraggingModel
                    window.currentDraggingModel = null
                    $(e.target).css("opacity", 0)
                    # e.target.remove()

    ### A configurable element bound to a property or page element
        Draggable, droppable, nestable. ###
    class window.views.draggableElement extends Backbone.View
        template: $("#draggable-element").html()
        controls: $("#drag-controls").html()
        tagName: 'div class="builder-element"'
        initialize: ->
            console.log("initing the parent class")
            self = @
            @index = @options.index
            _.bindAll(this, "render", "bindDrop", "bindDrag","setStyles","appendChild")
            @listenTo @model.get("child_els"), 'add', (m,c,o) ->
                self.appendChild(m,o)
            @listenTo @model, { 
                "change:styles": @setStyles
                "change:inFlow": ( model ) ->
                    if model.get("inFlow") is true
                         self.$el.slideDown("fast")
                    else 
                        self.$el.slideUp("fast").prev(".droppable-placeholder").remove()
                "remove": ->
                    self.$el.next(".droppable-placeholder").remove()
                    do self.remove
                "sorting": ->
                    self.$el.addClass("selected-element")
                "end-sorting": ->
                    if (self.$el.hasClass("ui-selected") is false)
                        self.$el.removeClass("selected-element")
            }
            do @bindDrop
            do @bindDrag
            console.log @events
        render: ->
            # For inherited views that don't want to overwrite render entirely, we have 
            # custom methods to accompany it.
            (@beforeRender || -> {})()
            that = @
            model = @model
            children = model.get "child_els" 
            $el =  @$el
            # Get model layout properties and set applicable as classes
            @setStyles()
            $el.html(_.template @template, model.toJSON()).append(_.template @controls, {})
            if children?
                _.each children.models , (el) ->
                    that.appendChild el, {}
            $el.hide().fadeIn(325)
            (@afterRender || -> {})()
            @
        appendChild: ( child , opts ) ->
            # We choose a view to render based on the model's specification, 
            # or default to a standard draggable.
            view = child.get("view") || "draggableElement"
            if child.get("inFlow") is true
                i = @index || sectionIndex
                draggable = $(new views[view]({model: child, index: i}).render().el).addClass("builder-child")
                if (opts? and !opts.at?)
                    @$el.append(draggable)
                else 
                    builderChildren = @$el.children(".builder-element")
                    if builderChildren.eq(opts.at).length 
                        builderChildren.eq(opts.at).before(draggable)
                    else @$el.append(draggable)
                globals.setPlaceholders($(draggable), @model.get("child_els"))
                allSections.at(@index).get("builder").removeExtras()
        setStyles: ->
            # Get all styling information associated with model
            styles = @model.get "styles"
            # Apply styling inline - ideal solution seems to be a combination 
            # of a class suite and inline styles for uncommon patterns
            if styles?
                @$el.css styles
        bindDrag: ->
            that = this
            cancel = ".config-menu-wrap, input, textarea, [contentEditable], [contenteditable], .add-list-item, .generic-list li, .no-drag"            
            # Set the element to be draggable.
            @$el.draggable
                cancel: cancel
                revert: true
                scrollSensitivity: 100
                helper: ->
                    # Get all selecged elements
                    selected = that.$el.closest("section").find(".ui-selected, .selected-element")
                    self = $(this)
                    if !self.hasClass("selected-element") then return self
                    # Make a wrapper for all elements
                    wrap = $("<div />").html(self.clone()).css("width", "100%")
                    # Append each selected item to the wrapper so the user can see what they drag
                    selected.each -> 
                        # Do not reappend the direct dragged item - it need not be selected, per se
                        # but may still be the subject of a drag. Do not reappend children.
                        unless self.is(this) or $(this).hasClass("builder-child")
                            wrap.append $(this).clone()
                    wrap.addClass("selected-element")
                cursor: "move"
                start: (e, ui) ->
                    if e.shiftKey is true
                        return false
                    sect_interface = allSections.at(that.index)
                    section = sect_interface.get("currentSection")
                    ui.helper.addClass("dragging")
                    if (ui.helper.hasClass("selected-element"))
                        allDraggingModels = section.gather()
                    else allDraggingModels = []
                    # When a drag starts, give the builder the model (or collection of such) so it can render on drop
                    if allDraggingModels.length > 1
                        window.currentDraggingModel = allDraggingModels
                    else window.currentDraggingModel = that.model
                stop: (e, ui) ->
                    $(ui.helper).removeClass("dragging")
        bindDrop: ->
            that = this
            @$el.droppable {
              greedy:true                                          # intercepts events from parent
              tolerance: 'pointer'                                 # only the location of the mouse determines drop zone.
              accept: '.builder-element, .generic-elements li'
              over: (e) ->
                $(e.target).addClass("over")
              out: (e)->
                $(e.target).removeClass("over")
              drop: (e,ui) ->   
                sect_interface = allSections.at(that.index || currIndex)
                section = sect_interface.get("currentSection")
                builder = sect_interface.get("builder")
                $(e.target).removeClass("over")
                model = that.model
                draggingModel = window.currentDraggingModel
                # if the dragged element is a direct child of its new parent, do nothing
                unless draggingModel.collection is model.get("child_els")
                 if model.blendModels(draggingModel) is true
                    $(ui.helper).remove()
                    # Lets the drag element know that it was a success
                    ui.draggable.data('dropped', true)
                    delete window.currentDraggingModel
                    window.currentDraggingModel = null
            }
        removeFromFlow: (e) ->        #  When they click the "X" in the config - remove the el from the builder
            that = @
            destroy = ->
                that.model.set("inFlow", false)
                e.stopPropagation()
                e.stopImmediatePropagation()  
            if e.type == "flowRemoveViaDrag"
                @$el.toggle("clip",  300, destroy)
            else do destroy
                
        test: ->
            console.log ("test")
        # Default 
        events: 
            "click": (e) ->
                layout = @model["layout-item"]
                if e.shiftKey is true
                    if (layout is false or typeof layout is "undefined")
                        @$el.trigger("select")
                    else 
                        @$el.trigger("deselect")
                    e.stopPropagation()
                    e.stopImmediatePropagation()
            "click .set-options": (e) ->
                $t = $(e.currentTarget)
                dropdown = $t.children(".dropdown")
                dropdown.fadeToggle(100);
                e.stopPropagation()
            "click .set-options li": (e) ->
                e.preventDefault()
                e.stopPropagation()                  # So as to stop the parent list from closing
            "click .remove-from-flow": "removeFromFlow"
            "flowRemoveViaDrag": "removeFromFlow"      # Stop the click event from bubbling up to the parent model, if there is one.:
            "click .config-panel": (e) ->            #  On click of the panel in the top right
                editor = new views.ElementEditor({model: @model, view: @}).render()
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
                console.log @
                @$el.addClass("active-sorting")
            "end-sorting": ->
                @$el.removeClass("active-sorting")

    window.views.SectionBuilder = Backbone.View.extend {
        initialize: ->
            @controller = @options.controller
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find("section")
            @collection = @options.collection
            that = @
            $el = @$el
            @listenTo @collection, {
                "add": (m , c, opts) ->
                    that.append(m, opts)
            }
            $el.droppable {
                accept: '.builder-element, .generic-elements li'
                hoverClass: "dragging"
                activeClass: "dragging" 
                greedy: true
                helper: 'clone'
                revert: 'invalid'
                tolerance: 'pointer'
                over: ->
                    # Here we have a blank function to overwrite the wrapper's over function. 
                    # Greedy precludes by order of DOM tree
                drop: ( event, ui ) -> 
                    curr = window.currentDraggingModel
                    c = curr.collection
                    # If the model is in a collection, and it's not the same one as the builder,
                    # IE not top level
                    if c? and c != that.collection
                        c.remove curr
                        curr.set "inFlow", true
                        that.collection.add curr 
                        delete window.currentDraggingModel
                        window.currentDraggingModel = null
                    else 
                        that.collection.add curr
            }
            $el.selectable {
                filter: '.builder-element'
                cancel: ".builder-element"
                tolerance: 'touch'
                selecting: (e,ui) ->
                    console.log e
                    $(ui.selecting). trigger "select"
                unselecting: (e,ui) ->
                    console.log ui
                    if (e.shiftKey is true) then return 
                    $item = $(ui.unselecting)
                    $item.trigger "deselect"
                    that.wrapper.find(".selected-element").trigger("deselect")
            }
        render: ->
            $el = @$el
            that = this
            $el.empty()
            _.each @collection.models, (element) ->
                that.append(element, {})

        append: (element, opts) ->
            view = element.get("view") || "draggableElement"
            #If the element has been taken out of the flow, don't render it.
            if element.get("inFlow") is false
                    return null
            draggable = new views[view]({model: element, index: @controller.index}).render().el
            if opts? && !opts.at?
                @$el.append draggable
            else 
                if @$el.children(".builder-element").eq(opts.at).length 
                    @$el.children(".builder-element").eq(opts.at).before(draggable)
                else @$el.children(".builder-element").eq(opts.at - 1).after(draggable)
            console.log @controller.get("currentSection")
            globals.setPlaceholders($(draggable), @controller.get("currentSection"))
            @removeExtras()
        removeExtras: ->
            @$el.find(".droppable-placeholder").each ->
                $t = $(this)
                if $t.next().hasClass("droppable-placeholder")
                    $t.next().remove()  
                if $t.prev().hasClass("droppable-placeholder")
                    $t.prev().remove()
    }
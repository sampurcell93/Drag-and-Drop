$(document).ready ->
    ### 
        MUST be bound to the window, so as not to leak into 
        global namespace and still have access to other scripts 
    ###

    window.copiedModel = null

    class window.models.Element extends Backbone.Model
        initialize: ->
            self = @
            # if @get("property")
            #     @listenTo @get("property"), "destroy", ->
            #         cc "destroy"
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
                title: "Default Title"
                editable: true
            }
        url: ->
            url = "/section/"
            url += if @id? then @id else ""
            url
        # Recursively makes models out of the standard javascript objects returned by ajax
        modelify: (basicObj) ->
            el = new models.Element(basicObj)
            el.deepCopy()
        # JSON returns as a single model whose submodels are standard json objects, not backbone models.
        # MODELIFY each standard json object, and its children, recursively.
        parse: (response) ->
            self = @
            section = []
            _.each response.currentSection, (element) ->
                section.push self.modelify(element)
            response
        blend: (putIn, opts) ->
            if !putIn? then return false
            defaults = opname: "change", at: 0
            options = _.extend defaults, opts || {}
            console.log options
            children = @get("child_els")
            hide = {no_history: true}
            # If put in is a collection
            if $.isArray(putIn) is true and putIn.length > 1
                # If we're adding an array of models, change the opname to reflect
                options.opname += " " + putIn.length + " "
                if putIn.indexOf(@) != -1
                    alert("you may not drag shit into itself. DIVIDE BY ZERO")
                    return false
                # Remove each model from its collection so that events are triggered
                # loop is necessary because of disjoint selection
                type = putIn[0].get("type")
                _.each putIn, (model, i) ->
                    if model.get("type") != type
                        options.subject = "element"
                    if model.collection?
                        model.collection.remove model, hide
                    options.no_history = true
                    if i < putIn.length - 1
                        children.add model, options
                    else
                        options.no_history = false
                        children.add model, options
                return true
            # Remove the model from its current collection, if there is such.
            else if putIn.collection?
                putIn.collection.remove putIn, hide
            children.add putIn, options

            true
        deepCopy: ->
            model = @
            clone = model.clone()
            # Shallow clone the model 
            children = clone.get("child_els")
            if $.isArray children
                children = new collections.Elements children
            children = children.clone()
            # check each settable value
            for attr of clone.attributes
                if attr == "child_els" then continue
                key = attr
                val = clone.attributes[attr]
                # For arrays, deep copy the array and set
                if $.isArray val
                    clone.attributes[attr] = val.deepClone()
                # Deep copy objects, too
                else if typeof val == "object"
                    clone.attributes[attr] = $.extend true, {}, val
            # deep copy each child model
            _.each children.models, (child) ->
                child = child.deepCopy()
            clone.set("child_els", children)
            clone


    window.collections.Elements = Backbone.Collection.extend {
        model: models.Element
        url: '/section/'
        # Takes in a new index, an origin index, and an optional collection
        # When collection is ommitted, the collection uses this.collection
        reorder: (newIndex, originalIndex, collection, options) ->
            if options? and options.opname? then op = options.opname
            if newIndex is originalIndex then return this
            # Get the original index of the moved item, and save the item
            collection = collection || @
            temp = collection.at(originalIndex)
            # Remove it from the collection
            collection.remove(temp, {organizer: {itemRender: false, render: false},  no_history: true})
            # Reinsert it at its new index
            collection.add(temp, {at: newIndex, organizer: {itemRender: false, render: false}, opname: op})
            this
        # Returns an array of all models that match the property, recursively. Defaults to layout item search
        gather: (prop) ->
            # Normally would use _.filter() here but we are looking for model properties - not their .get()/.set() attributes
            prop = prop || "selected"
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
                # deep_copy_model = element.clone()
                # children = deep_copy_model.get("child_els")
                # deep_copy_model.set("child_els", children.clone(), {no_history: true})
                # copy.add new models.Element(deep_copy_model.toJSON()), {no_history: true}
                copy.add element.deepCopy(), {no_history: true }
            copy
        compare: (collection) ->
            _.isEqual(@models, collection.models)
    }

    class window.views.droppablePlaceholder extends Backbone.View
        contextMenu: $("#placeholder-context").html()
        tagName: 'div'
        className: 'droppable-placeholder'
        events:
            "click .paste-element": (e) ->
                clone = window.copiedModel
                dropZone = @$el
                # Get index of the placeholder
                insertAt = dropZone.siblings(".builder-element").index(dropZone.prev()) + 1
                # Make sure colection exists
                if @collection? and clone?
                    # Throw in copied model
                    @collection.add clone, {at: insertAt, opname: 'Paste'}
                    # Recopy model
                    if $.isArray(clone)
                        models = []
                        _.each clone, (model) ->
                            models.push model.deepCopy()
                        window.copiedModel = models
                    else
                        window.copiedModel = clone.deepCopy()
                e.stopPropagation()
            "remove": "remove"
            "contextmenu": (e) ->
                e.stopPropagation()
                if window.copiedModel == null then return true
                $(".context-menu").remove()
                e.preventDefault()
                $el = @$el
                pageX = e.pageX - $el.offset().left
                pageY = e.pageY - $el.offset().top
                # Remove all other right click menus
                $("<ul />").html(_.template(@contextMenu, {})).
                addClass("context-menu").
                css({"top":pageY + "px", "left": pageX + "px"}).
                appendTo @$el
                false
        render: ->
            self = @
            @$el.droppable
                accept: ".builder-element, .outside-draggables li, .property"
                greedy: true
                tolerance: 'pointer' 
                over: (e, ui) ->
                    if $(document.body).hasClass("active-modal") then return false
                    $(e.target).addClass("show")
                out: (e, ui) ->
                    $(e.target).removeClass("show").find("ul").remove()
                drop: (e,ui) ->
                    $(e.target).removeClass("show")
                    $(".over").removeClass("over")
                    if $(document.body).hasClass("active-modal") then return false
                    dropZone = $(e.target)
                    insertAt = dropZone.siblings(".builder-element").index(dropZone.prev()) + 1
                    curr = window.currentDraggingModel
                    if !$.isArray(curr) and curr.get("inFlow") is false
                        cc "drop inflowing"
                        curr.set("inFlow", true)
                        return
                    parent = self.collection.model 
                    if typeof parent is "function" or !parent? then parent = self.collection
                    parent.blend(curr, {at: insertAt})
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
            _.bindAll(this, "render", "bindDrag","bindListeners", "bindResize")
            @on "bindListeners", @bindListeners
            # Bind the drag event to the el
            do @bindDrag
            # Bind all model listeners
            do @bindListeners
            # Bind resizable
        bindResize: ->
            parent = @options.parent
            parent_width = parent.width()
            grid_block = (parent_width) / 6
            @$el.resizable
                handles: "e"
                containment: 'parent'
                grid: grid_block
                autoHide: true
                resize: (e, ui) ->
                    # Get the width fo the parent in divide it into sixths
                    parent_width = parent.width()
                    # We need to set this each time so that if the window is resized, the grid changes
                    grid_block = (parent_width) / 6
                    $(@).resizable("option", "grid", grid_block)
                    # Stop a bug where draggable interferes with resizable
                    ui.helper.css({"position": "relative", "top":"", "left":""})
                start: (e, ui) ->
                    ui.helper.css({"position": "relative", "top":"", "left":""})
        bindListeners: ->
            self = @
            # Unbind previous listeners
            @stopListening()
            @listenTo @model.get("child_els"),
            {   'add': (m,c,o) ->
                    unless (typeof self.itemName == "undefined")
                        m.set("view", self.itemName)
                    self.appendChild(m,o)
                'reset': @render
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
                        self.$el.slideUp("fast").next(".droppable-placeholder").hide()
                        self.$el.prev(".droppable-placeholder").hide()
                "remove": ->
                    self.$el.next(".droppable-placeholder").remove()
                    self.remove()
                "link-feedback": ->
                    self.$el.addClass("link-feedback")
                "end-feedback": ->
                    self.$el.removeClass("link-feedback")
                "renderBase": ->
                    self.render(false)
                "render": ->
                    self.render(true)
                "showConfigModal": @showConfigModal
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
            model["selected"] = false
            children = model.get "child_els" 
            $el =  @$el
            $el.html(_.template @template, model.toJSON())
            if @controls? then $el.append(_.template @controls, model.toJSON())
            if $el.children(".children").length is 0
                    $el.append($("<ul/>").addClass("children"))
            if children? and do_children is true
                if children.length > 0 then @$el.children(".placeholder").hide()
                _.each children.models , (el) ->
                    that.appendChild el, {}
            @applyClasses()
            @checkPlaceholder()
            @$(".view-attrs").first().trigger("click")
            (@afterRender || -> 
                # $el.hide().fadeIn(325)
            )()
            # do @bindResize
            @
        bindDrag: ->
            that = this
            # Set the element to be draggable.
            @$el.draggable
                cancel: ".no-drag, .context-menu, .ui-resizable-handle"
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
        removeFromFlow: (e) ->        #  When they click the "X" in the config - remove the el from the builder
            that = @
            out = ->
                that.model.set("inFlow", false, no_history: true )
            if e.type == "flowRemoveViaDrag"
                @$el.toggle("clip",  300, out)
            else do out
            e.stopPropagation()
            e.stopImmediatePropagation()  
        checkPlaceholder: ->
        applyClasses: ->
            $el = @$el
            # "class" is a reserved keyword. style instead
            _.each @model.get("classes"), (style) ->
                $el.addClass(style)

        # Grabs all selected elements and groupes them into a barebones layout
        blankLayout: (e) ->
            cc currIndex
            collection = allSections.at(window.currIndex).get("currentSection")
            selected = collection.gather()
            if selected.length is 0 or selected.length is 1 then return
            layoutIndex = collection.indexOf(selected[0])
            collection.add(layout = new models.Element({view: 'DynamicLayout', type: 'Dynamic Layout'}), {at: layoutIndex, no_history: true})
            _.each selected , (model) ->
                if model.collection?
                    model.collection.remove model, {no_history: true}
                layout.get("child_els").add model
            if e? then e.stopPropagation()
            @
        exportAsSection: ->
            title = @model.get "title"
            if title == "" or typeof title is "undefined" or title == "Default Section Title"
                alert "You need to enter a title"
                return false
            # _.each @model.get("currentSection").models, (model) ->
            #     model.unset "inFlow", {silent: true}
            copy = new models.SectionController()
            wrapper = new collections.Elements()
            wrapper.add @model
            copy.set({
                currentSection: wrapper
                section_title: title
            })
            copy.save(null, {
                success: ->
                    $("<div />").addClass("modal center").html("You saved the section").appendTo(document.body);
                    $(document.body).addClass("active-modal")
                    $(".modal").delay(2000).fadeOut "fast", ->
                        $(@).remove()
                        $(document.body).removeClass("active-modal")
            })
            true
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
            item =  @model.toJSON()
            item.selected = false
            if @model["selected"] is true then item.selected = true 
            # Remove all other right click menus
            $("<ul />").html(_.template(@contextMenu, item)).
            addClass("context-menu").
            css({"top":pageY + "px", "left": pageX + "px"}).
            appendTo(@$el)
            e.stopPropagation()
            false
        unbindContextMenu: (e) ->
            cc "unbinding"
            menu = $(".context-menu") 
            if e? and $(e.currentTarget).hasClass("context-menu") then return false
            menu.remove()
        showConfigModal: (e) ->     
            defaultEditor = if @model.get("layout") == true then "BaseLayoutEditor" else "BaseEditor"
            editor = views.editors[@edit_view || @model.get("view") || defaultEditor]
            if editor? then editor = new editor({model: @model, link_el: @el}).render()
            else editor = new views.editors[defaultEditor]({model: @model, link_el: @el}).render()
            $(editor.el).launchModal()
        selectEl: ->
            layout = @model["selected"]
            if (layout is false or typeof layout is "undefined")
                @$el.trigger("select")
            else 
                @$el.trigger("deselect")
        # Default events for any draggable - basically configuration settings.
        events: 
            # Copy the element to the "clipboard"
            "click .context-menu > li.copy-element": ->
                copy = @model.deepCopy()
                window.copiedModel = copy
            "click .context-menu > li.cut-element": ->
                copy = @model.deepCopy()
                window.copiedModel = copy
                # Cut the element
                @model.collection.remove @model, {opname: 'Cut'}
            "click .context-menu > li.select-this": ->
                @selectEl()
            "click .group-elements": "blankLayout"
            "click .destroy-element": ->
                @model.destroy()
            "click .context-menu li": (e) ->
                $t = $(e.currentTarget)
                unless $t.hasClass("disabled")
                    # Stop the context menu from closing
                    @unbindContextMenu()
            # for debugging
            "dblclick": (e) ->
                console.log @model.toJSON()
                @showConfigModal()
                e.stopPropagation()
            "click": (e) ->
                @unbindContextMenu(e)
                @$el.find(".dropdown").hide()
                if e.shiftKey is true or e.ctrlKey is true
                    @selectEl()
                e.preventDefault()
                e.stopPropagation()
                false
            # for right click functionality users expect
            "contextmenu": "bindContextMenu"
            "click .export": "exportAsSection"
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
            "click .view-attrs": (e) ->
                props = new views.toolbelt.Actives({model: @model}).render().el
                $(".quick-props").find("ul").html props
                if e? and e.isTrigger is true then return 
                button = $(".quick-props").find(".close-arrow")
                button.trigger "click"
            "click .remove-from-flow": "removeFromFlow"
            "flowRemoveViaDrag": "removeFromFlow" 
            "click .config-panel": "showConfigModal"
            "select" : (e) ->
                # Setting this property will not affect rendering immediately, so make it silent. 
                @model["selected"] = true
                @$el.addClass("selected-element")
                e.stopPropagation()
                e.stopImmediatePropagation()
            "deselect": (e) ->
                @model["selected"] = false
                @$el.removeClass("selected-element")
                e.stopPropagation()
                e.stopImmediatePropagation()
            "sorting": ->
                @$el.addClass("active-sorting")
            "end-sorting": ->
                @$el.removeClass("active-sorting")
            "mouseleave": ->
                @$(".set-options > ul").hide()
            "mouseover .config-menu-wrap > li": (e) ->
                $t = $ e.currentTarget
                $t.data("over", true) 
                self = $t
                window.setTimeout(->
                    if $t.data("over")  == true
                        self.showTooltip()
                ,500)
                e.stopPropagation()
            "mouseleave .config-menu-wrap > li": (e) ->
                $t = $ e.currentTarget
                $t.data("over", false) 
                $t.hideTooltip()
                e.stopPropagation()

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
            @$el.append draggable = $(new views[view]({model: element, parent: @$el}).render().el)
            @removeExtraPlaceholders()
            draggable
        removeExtraPlaceholders: ->
            @$el.find(".droppable-placeholder").each ->
                $t = $ @
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
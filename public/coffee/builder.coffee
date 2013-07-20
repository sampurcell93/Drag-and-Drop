$(document).ready ->
    ### 
        MUST be bound to the window, so as not to leak into 
        global namespace and still have access to other scripts 
    ###
    window.models = {}
    window.views = {}
    window.collections = {} 

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
            # Remove the model from its current collection, if there is such.
            if putIn.collection?
                putIn.collection.remove putIn
            # Get all current child elements, add the dropped one, and put the collection back in
            children = @get "child_els"
            if children?
                @set "child_els", children.add(putIn)
    }


    window.collections.Elements = Backbone.Collection.extend {
        model: models.Element
        url: '/section/'
         # Takes in a new index, an origin index, and an optional collection
        # When collection is ommitted, the collection uses this.collection
        reorder: (newIndex, originalIndex, collection) ->
            console.log originalIndex, newIndex
            # Get the original index of the moved item, and save the item
            collection = collection || @
            temp = collection.at(originalIndex)
            # Remove it from the collection
            collection.remove(temp, {sortableItemRender: false})
            # Reinsert it at its new index
            collection.add(temp, {at: newIndex})
            this
    }
    # A list of elements which can be reordered. Basically, the overarching section architecture.
    window.views.ElementOrganizer = Backbone.View.extend({
        initialize: ->
            @controller = @options.controller
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find(".organize-elements")
            @collection = @options.collection
            @listenTo(@collection, {
                "add": (model, collection, options) -> 
                    that.append(model, options)
            })
            ### Render the list, then apply the drag and drop, and sortable functions. ###
            _.bindAll(this,"append","render")
            that = this
            @$el.sortable {
                axis: 'y'
                tolerance: 'touch'
                connectWith: 'ul'
                containment: 'parent'
                handle: '.sort-element'
                items: 'li'
                start: (e,ui)->
                    that.origIndex = $(ui.item).addClass("moving-sort").index()
                stop: (e, ui) ->
                    that.collection.reorder $(ui.item).removeClass("moving-sort").index(), that.origIndex
            }
            this
        render: (e) ->
            console.log("rendering organizer")
            $el = @$el
            $el.children().remove()
            that = this
            outOfFlow = []
            index = that.options.index || sectionIndex
            _.each @collection.models, (el) ->
                # If the element has been removed, we want to display it
                # as an option at the bottom of the architecture panel
                if el.get("inFlow") is false
                    outOfFlow.push el
                    return
                that.append(el, {index: index, outOfFlow: false})
            # Once every element still in flow has been rendered, render those not, 
            # at bottom, with an option to distinguish them.
            _.each outOfFlow, (out, i) ->
                that.append(out, { outOfFlow: true, index: index})
            this
        # Method to avoid having ot rerender an entire list on add
        append: ( element, options ) -> 
            # Because the only mechanism of sorting is the sortable ui itself,
            # no method should insert elements into the list, aside from appending at the end.
            if options.at? then return this
            opts = this.options
            opts.model = element
            $.extend(opts,options)
            itemView = new views.SortableElementItem(opts)
            this.$el.append(itemView.render().el)
    });

    window.views.SortableElementItem = Backbone.View.extend {
        tagName: 'li class="property"'
        template: $("#element-sortable-item").html()
        initialize: ->
            that = this
            # When the linked model is removed from a collection, rerender this
            # @listenTo @model, "change:inFlow", @render
            @listenTo @model,  {
                "render": @render
                "destroy": @remove
                "remove": (model, collection, opts) ->
                    if opts.sortableItemRender is false then return 
                    do that.remove
                "change:customText": (model) ->
                    that.$el.children(".element-title").first().text(model.get("customText"))
                "change:customHeader": (model) ->
                    that.$el.children(".element-title").first().text(model.get("customHeader"))
                "change:inFlow": (model) ->
                    if (model.get("inFlow") is false)
                        @$el.addClass("out-of-flow")
                    else @$el.removeClass("out-of-flow")

            }
            @listenTo @model.get("child_els"), {"add": @render, "remove": @render, "change:inFlow": @render}
        render: ->
            console.log "rendering item in organizer"
            $el = @$el
            $el.html _.template @template, @model.toJSON()
            that = this
            # Same recursion as draggable element.
            if @model.get("inFlow") is false
                $el.addClass("out-of-flow")
                $("<div />").addClass("activate-element").text("m").prependTo($el)
                $("<div />").addClass("destroy-element").text("g").prependTo($el)
            else 
                $el.removeClass("out-of-flow") 
            @outOfFlow = []
            _.each @model.get("child_els").models, (el) ->
                that.append el
            childList = $el.children(".child-list")
            # Only make element draggable if there is more than one at a certain level of hierarchy
            if childList.children().length > 1
                childList.sortable {
                    items: 'li'
                    axis: 'y'
                    containment: 'parent'
                    start: (e,ui)->
                        that.origIndex = $(ui.item).index()
                    stop: (e, ui) ->
                        console.log that.options.index
                        that.model.get("child_els").reorder $(ui.item).index(), that.origIndex
                }   
            this
        append: ( child, opts )->
            $el = @$el
            childList = $el.children(".child-list")
            opts = {model: child, child: true, index: @options.index || sectionIndex}
            if child.get("inFlow") is false  
                opts.outOfFlow = true
                $el.addClass("out-of-flow")
                $("<div />").addClass("activate-element").text("m").prependTo($el)
                $("<div />").addClass("destroy-element").text("g").prependTo($el)
            childList.append new views.SortableElementItem(opts).render().el
        events:
            "mousedown .sort-element": (e) ->
                @model.trigger("dragging")
            "mouseup .sort-element": (e) ->
                @model.trigger("dropped")
            "click .activate-element": ->
                @model.set "inFlow", true
            "click .destroy-element": ->
                @model.destroy()
    }


    ### A configurable element bound to a property or page element
        Draggable, droppable, nestable. ###
    window.views.draggableElement = Backbone.View.extend({
        template: $("#draggable-element").html()
        controls: $("#drag-controls").html()
        tagName: 'div class="builder-element"'
        initialize: ->
            self = @
            @index = @options.index
            @builder = @options.builder
            _.bindAll(this, "render", "bindDrop", "bindDrag","setStyles")
            @listenTo @model.get("child_els"), 'add', (m,c,o) ->
                console.log(o)
                self.appendChild(m,o)
            @listenTo @model, { 
                "change:styles": @render
                "change:inFlow": ( model ) ->
                    if model.get("inFlow") is true
                         self.$el.slideDown("fast")
                    else self.$el.slideUp("fast")
                "remove": @remove
                "dragging": (e) ->
            }
            # Gets the model type
            # console.log @ instanceof views.draggableElement 
            @bindDrop()
            @bindDrag()
        render: ->
            console.log "rendering draggable"
            that = @
            model = @model
            children = model.get "child_els" 
            $el =  @$el
            # Get model layout properties and set applicable as classes
            @setStyles()
            # Here, we either use the default template for a draggable, or we use the model's custom template
            # This is useful for generic elements like buttons, lists, and others who do not fit the property model
            # Because tagName is preserved, so is styling.
            template = $(model.get("template")).html() || @template
            $el.html(_.template template, model.toJSON()).append(_.template @controls, {})
            if children?
                _.each children.models , (el) ->
                    that.appendChild el, {}
            # Check if previous element is floated - if not, clearfix.
            # Ordinarily, the following would be part of the native template but with multiple 
            # templates being applied to this generic view, we can just append it.
            this
        appendChild: ( child , opts ) ->
            # Necessary to filter sub elements.
            if child.get("inFlow") is true
                i = @index || sectionIndex
                draggable = new views.draggableElement({model: child, index: i}).render().el
                if (opts? and !opts.at?)
                    @$el.append(draggable)
                else 
                    if @$el.children(".builder-element").eq(opts.at).length 
                        @$el.children(".builder-element").eq(opts.at).before(draggable)
                    else @$el.children(".builder-element").eq(opts.at - 1).after(draggable)

        setStyles: ->
            # Get all styling information associated with model
            styles = @model.get "styles"
            # Apply styling inline - ideal solution seems to be a combination 
            # of a class suite and inline styles for uncommon patterns
            if styles?
                @$el.css styles
        bindDrag: ->
            that = this
            cancel = ".config-menu-wrap, input, textarea"            
            # if draggable element is a child of another, do not cancel on .child selection
            cancel += if @options.child? then "" else ", .child"
            # Set the element to be draggable.
            @$el.draggable {
                cancel: cancel
                # When the drop is bad, do nothing
                revert: "invalid"
                # helper: "clone",
                cursor: "move"
                start: (e, ui) ->
                    sect_interface = allSections.at(that.index || sectionIndex)
                    section = sect_interface.get("currentSection")
                    builder = sect_interface.get("builder")
                    $(ui.helper).addClass("dragging")
                    # When a drag starts, give the builder the model so it can render on drop
                    if builder?
                        builder.currentModel = that.model
                        builder.fromSideBar = false
                        # Weird bug fix - need a blank log for it to register - probably coffeescript stupidity.
                        console.log
                stop: (e, ui) ->
                    $(ui.helper).removeClass("dragging")
                }
        bindDrop: ->
            that = this
            @$el.droppable {
            # this droppable should be greedy to intercept events from the section wrapper
              greedy:true
            # only the location of the mouse determines drop zone.
              tolerance: 'pointer'
              revert: 'invalid'
            # accepts all draggables
              accept: '*'
              over: (e) ->
                $(e.target).addClass("over")
              out: (e)->
                $(e.target).removeClass("over")
              drop: (e,ui) ->
                sect_interface = allSections.at(that.index || sectionIndex)
                section = sect_interface.get("currentSection")
                builder = sect_interface.get("builder")
                ### Deals with the actual layout changes ###
                $(e.target).removeClass("over")
                # Get the model currently being dragged
                draggingModel = builder.currentModel
                flow = draggingModel.get("inFlow")
                # If it's not in the flow, then it can be dragged in.
                #  If it's not from the sidebar, it can be dragged in.
                if (flow is false or typeof flow is "undefined") or builder.fromSideBar is false
                    model = that.model
                    # if the dragged element is a direct child of its new parent, do nothing
                    if draggingModel.collection is that.model.get("child_els") 
                        console.log "same parent"
                        return
                    $(ui.helper).remove()
                    # Lets the drag element know that it was a success
                    # This event fires before the drag stop event
                    ui.draggable.data('dropped', true)
                    ### Now, we must consolidate models ###
                    model.blendModels(draggingModel)
                else alert "That item is already in the page flow."
            }
        events: 
            "click": (e) ->
                layout = @model["layout-item"]
                if e.shiftKey is true
                    if (layout is false or typeof layout is "undefined")
                        @$el.trigger("select")
                    else 
                        @$el.trigger("deselect")
                    e.preventDefault()
            "click .set-options": (e) ->
                console.log @model.get "type"
                $t = $(e.currentTarget)
                dropdown = $t.children(".dropdown")
                dropdown.fadeToggle(100);
                e.stopPropagation()
            "click .set-options li": (e) ->
                # So as to stop the parent list from closing
                e.preventDefault()
                e.stopPropagation()
            "click .remove-from-flow": (e) ->
                @model.set("inFlow", false)
                # Stop the click event from bubbling up to the parent model, if there is one.
                e.stopPropagation()
                e.stopImmediatePropagation()
            "click .config-panel": (e) ->
                console.log @model.get "type"
                editor = new views.ElementEditor({model: @model, view: @}).render()
            "select" : (e) ->
                # Setting this property will not affect rendering immediately, so make it silent. 
                @model["layout-item"] = true
                @$el.addClass("selected-element")
            "deselect": ->
                @model["layout-item"] = false
                @$el.removeClass("selected-element")
            "keyup .generic-header": (e) ->
                @model.set 'customHeader', $(e.currentTarget).val()
                e.stopPropagation()
            "keyup .generic-text": (e) ->
                @model.set 'customText', $(e.currentTarget).val()
                # Stop event from bubbling to parent model.
                e.stopPropagation()
    })

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
                accept: '.builder-element, li'
                hoverClass: "dragging"
                activeClass: "dragging" 
                helper: 'clone'
                revert: 'invalid'
                tolerance: 'pointer'
                drop: ( event, ui ) -> 
                    curr = that.currentModel
                    # If the element is not already on the page,
                    if (curr.get("inFlow") is false or typeof curr.get "inFlow" is "undefined") or that.fromSideBar is false
                        c = curr.collection
                        # If the model is in a collection, and it's not the same one as the builder,
                        # IE not top level
                        if c? and c is not that.collection
                            c.remove curr
                            curr.set "inFlow", true
                            that.collection.add curr 
                            ui.draggable.data('dropped', true)  
                    # Otherwise, we do not want duplicates
                    else alert "That element is already on the page!"
            }
            $el.selectable {
                filter: '.builder-element'
                tolerance: 'touch'
                cancel: '.builder-element'
                selecting: (e,ui) ->
                    $(".ui-selecting"). trigger "select"
                unselecting: (e,ui) ->
                    console.log "unselecting"
                    $(".ui-selecting").trigger "deselect"
                selected: (e,ui) ->
                    $(".ui-selected").trigger "select"
                unselected: (e,ui) ->
                    $(".ui-selectee").trigger("deselect")
            }
            @currentModel = null
        render: ->
            $el = @$el
            that = this
            $el.empty()
            _.each @collection.models, (element) ->
                that.append(element, {})

        append: (element, opts) ->
            #If the element has been taken out of the flow, don't render it.
            if element.get("inFlow") is false
                    return null
            draggable = new views.draggableElement({model: element, index: @options.index}).render().el
            if opts? && !opts.at?
                @$el.append draggable
            else 
                if @$el.children(".builder-element").eq(opts.at).length 
                    @$el.children(".builder-element").eq(opts.at).before(draggable)
                else @$el.children(".builder-element").eq(opts.at - 1).after(draggable)
       
    }
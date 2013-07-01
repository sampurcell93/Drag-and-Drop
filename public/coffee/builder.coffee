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
            self = @
            response.child_els = @modelify(response.child_els)
            response
    }


    window.collections.Elements = Backbone.Collection.extend {
        model: models.Element
        url: '/section/'
        blendModels: (addTo, putIn) ->
            # Remove the model from its current collection, if there is such.
            if putIn.collection?
                putIn.collection.remove putIn
            # Get all current child elements, add the dropped one, and put the collection back in
            children = addTo.get "child_els"
            if children?
                addTo.set "child_els", children.add putIn
                # This line is bad, but for some reason, the event watcher bound to the organizer fires too early.
                # TODO: figure that out!
                organizer.render()
    }
    # A list of elements which can be reordered. Basically, the overarching section architecture.
    window.views.ElementOrganizer = Backbone.View.extend({
        el: '#organize-elements'
        initialize: ->
            ### Render the list, then apply the drag and drop, and sortable functions. ###
            _.bindAll(this,"reorderCollection","render")
            @collection.on "change", @render, @
            @collection.on "add", @render, @
            @render()
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
                    that.reorderCollection $(ui.item).removeClass("moving-sort").index(), that.origIndex
            }
        render: ->
            $el = @$el
            $el.empty()
            that = this
            outOfFlow = []
            _.each @collection.models, (el) ->
                # If the element has been removed, we want to display it
                # as an option at the bottom of the architecture panel
                if el.get("inFlow") is false
                    outOfFlow.push el
                    return
                # Make a new sortable list item from the element
                itemView = new views.SortableElementItem({model: el})
                $el.append(itemView.render().el)
            # Once every element still in flow has been rendered, render those not, 
            # at bottom, with an option to distinguish them.
            _.each outOfFlow, (out, i) ->
                itemView = new views.SortableElementItem({model: out, outOfFlow: true})
                $el.append(itemView.render().el)
        # Takes in a new index, an origin index, and an optional collection
        # When collection is ommitted, the collection uses this.collection
        reorderCollection: (newIndex, originalIndex, collection) ->
            # Get the original index of the moved item, and save the item
            collection = collection || @collection
            temp = collection.at(originalIndex)
            # Remove it from the collection
            collection.remove(temp, {silent: true})
            # Reinsert it at its new index
            collection.add(temp, {at: newIndex, silent: true})
            # Render shit
            builder.render()
    });

    window.views.SortableElementItem = Backbone.View.extend {
        tagName: 'li class="property"'
        template: $("#element-sortable-item").html()
        initialize: ->
            that = this
            @listenTo @model, 'change', @render
            @listenTo @model.get("child_els"), 'change', @render
            @$el.draggable {
                cancel: ".sort-element, .destroy-element, .activate-element", 
                revert: "invalid", 
                helper: "clone",
                cursor: "move",
                cursorAt: {top: 50}
                start: ->
                    if builder?
                        builder.currentModel = that.model
                        builder.fromSideBar = true
            }
        render: ->
            $el = @$el
            $el.html _.template @template, @model.toJSON()
            childList = $el.children(".child-list")
            that = this
            # Same recursion as draggable element. 
            @outOfFlow = []
            _.each @model.get("child_els").models, (el) ->
                if el.get("inFlow") is true
                    childList.append new views.SortableElementItem({model: el, child: true}).render().el
                else  
                    childList.append new views.SortableElementItem({model: el, child: true, outOfFlow: true}).render().el
            if @options.outOfFlow is true
                $el.addClass("out-of-flow")
                $("<div />").addClass("activate-element").text("m").prependTo($el)
                $("<div />").addClass("destroy-element").text("g").prependTo($el)

            # Only make element draggable if there is more than one at a certain level of hierarchy
            if childList.children().length > 1
                childList.sortable {
                    items: 'li'
                    axis: 'y'
                    containment: 'parent'
                    start: (e,ui)->
                        that.origIndex = $(ui.item).index()
                    stop: (e, ui) ->
                        organizer.reorderCollection $(ui.item).index(), that.origIndex, that.model.get("child_els")
                }   
            this
        events:
            "click .sort-element": (e) -> 
                console.log $(e.target)
                e.stopImmediatePropagation()
            "click .activate-element": ->
                @model.set "inFlow", true
            "click .destroy-element": ->
                @model.destroy()
                @remove()
    }


    ### A configurable element bound to a property or page element
        Draggable, droppable, nestable. ###
    window.views.draggableElement = Backbone.View.extend({
        template: $("#draggable-element").html()
        controls: $("#drag-controls").html()
        tagName: 'div class="builder-element"'
        initialize: ->
            _.bindAll(this, "render", "bindDrop", "bindDrag","distance","setStyles")
            @listenTo @model, 'change', @render
            @listenTo @model.get("child_els"), 'change', @render
            # Gets the model type
            # console.log @ instanceof views.draggableElement 
        render: ->
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
            console.log template, model.get("template")
            $el.html(_.template template, model.toJSON()).append(_.template @controls, {title: 'yo'})
            if children?
                _.each children.models , (el) ->
                    # Necessary to filter sub elements.
                    if el.get("inFlow") is true
                        draggable = new views.draggableElement({model: el}).render().el
                        that.$el.append(draggable)
            # Check if previous element is floated - if not, clearfix.
            if $el.prev(".builder-element").css("float") == "none"
                $el.before $("<div />").addClass("clear")
            # Ordinarily, the following would be part of the native template but with multiple 
            # templates being applied to this generic view, we can just append it.

            @bindDrop()
            @bindDrag()
            this
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
                    $(ui.helper).addClass("dragging")
                    # When a drag starts, give the builder the model so it can render on drop
                    if builder?
                        builder.currentModel = that.model
                        builder.fromSideBar = false
                        # Weird bug fix - need a blank log for it to register - probably coffeescript stupidity.
                        console.log
                stop: (e, ui) ->
                    $(ui.helper).removeClass("dragging")
                    # If the drop was a success, remove the original and preserve the clone
                    if ui.helper.data('dropped') is true
                        $(e.target).remove()
            }
        # Algebra 1
        distance: (point1, point2) ->
            xs = 0
            ys = 0 
            xs = point2.left - point1.left
            xs = xs * xs
            ys = point2.top - point1.top
            ys = ys * ys
            Math.sqrt( xs + ys )
        bindDrop: ->
            that = this
            @$el.droppable {
            # this droppable should be greedy to intercept events from the section wrapper
              greedy:true
            # only the location of the mouse determines drop zone.
              tolerance: 'pointer'
            # accepts all draggables
              accept: '*'
              over: (e) ->
                $(e.target).addClass("over")
              out: (e)->
                $(e.target).removeClass("over")
              drop: (e,ui) ->
                ### Deals with the actual layout changes ###
                $(e.target).removeClass("over")
                # Get the model currently being dragged
                curr = builder.currentModel
                flow = curr.get("inFlow")
                # If it's not in the flow, then it can be dragged in.
                #  If it's not from the sidebar, it can be dragged in.
                if (flow is false or typeof flow is "undefined") or builder.fromSideBar is false
                    curr.set "inFlow",true
                    # remove the clone
                    $(ui.item).remove()
                    # Lets the drag element know that it was a success
                    # This event fires before the drag stop event
                    ui.draggable.data('dropped', true)
                    ### Now, we must consolidate models ###
                    builder.collection.blendModels(that.model, curr)
                    # And finally render the newly blended parent model, with its subcollection.
                    that.render()
                else alert "That item is already in the page flow."
            }
        events: 
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
                self = @
                console.log @model.get "type"
                @$el.slideUp "fast", ->
                    self.remove()
                    self.model.set "inFlow", false
                # Stop the click event from bubbling up to the parent model, if there is one.
                e.stopPropagation()
            "click .config-panel": (e) ->
                console.log @model.get "type"
                editor = new views.ElementEditor({model: @model, view: @}).render()
            "select" : (e) ->
                # Setting this property will not affect rendering immediately, so make it silent. 
                @model.set("layout-item", true, {silent: true})
            "deselect": ->
                console.log "deselecting"
                @model.set("layout-item", false, {silent: true})
            "change input": (e) ->
                @model.set 'customHeader', $(e.currentTarget).val()
                e.stopImmediatePropagation()
            "keyup textarea": (e) ->
                @model.set 'customText', $(e.currentTarget).val()
                $(e.currentTarget).focus()
    })

    window.views.SectionBuilder = Backbone.View.extend {
        el: 'section.builder-container'
        initialize: ->
            @render()
            that = @
            $el = @$el
            @collection.on "add", @render, @
            @collection.on "change:inFlow", @render, @
            $el.droppable {
                accept: 'li, .builder-element'
                hoverClass: "dragging"
                activeClass: "dragging" 
                tolerance: 'pointer'
                drop: ( event, ui ) -> 
                    # Children of the builder are no longer simply properties - 
                    # they are elements, which may contain properties and other 
                    # data, metadata, ui elements, et cetera.
                    curr = that.currentModel
                    # If the element is not already on the page,
                    if (curr.get("inFlow") is false or typeof curr.get "inFlow" is "undefined") or that.fromSideBar is false
                        # Render a new draggable element and append it to the list
                        c = curr.collection
                        if c?
                            c.remove curr, {silent: true }
                        that.collection.add curr, {silent: true}
                        temp = new views.draggableElement({model: curr}).render().el
                        # It is not in the flow again.
                        that.$el.append(temp)
                        console.log "dropping in main builder"
                        curr.set "inFlow", true
                        ui.draggable.data('dropped', true)
                        $(ui.item).remove()
                        organizer.render()
                    # Otherwise, we do not want duplicates
                    else alert "That element is already on the page!"
            }
            $el.sortable {
                axis: 'y'
                tolerance: 'touch'
                handle: '.sort-element'
                items: '.builder-element'
                cursorAt: {top: 50}
                stop: (e) ->
                   e.stopPropagation()
            }
            @$el.selectable {
                filter: '.builder-element'
                tolerance: 'touch'
                cancel: '.builder-element'
                selecting: (e,ui) ->
                    console.log "selecting"
                    $(".ui-selecting").addClass("selected-element"). trigger "select"
                unselecting: (e,ui) ->
                    console.log "unselecting"
                    $(".ui-selecting").removeClass("selected-element").trigger "deselect"
                selected: (e,ui) ->
                    $(".ui-selected").addClass("selected-element").trigger "select"
                unselected: (e,ui) ->
                    $(".ui-selected").removeClass("selected-element").trigger("deselect")
            }
            @currentModel = null
        render: ->
            $el = @$el
            that = this
            $el.empty()
            # Using a container appended to out of DOM, then appended to the el once
            # is preferable to appending to the el directly, as this method reduces 
            # rendering pixel recalculation for the browser.
            container = document.createDocumentFragment()
            _.each @collection.models, (element) ->
                #If the element has been taken out of the flow, don't render it.
                if element.get("inFlow") is false
                    return
                # Even better, let's use NO jQuery. Shit is fast!
                container.appendChild(new views.draggableElement({model: element}).render().el)
            $el.append(container)
    }
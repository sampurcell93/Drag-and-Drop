$(document).ready ->
    ### 
        MUST be bound to the window, so as not to leak into 
        global namespace and still have access to other scripts 
    ###

    window.models = {}
    window.views = {}
    window.collections = {}


    window.collections.Elements = Backbone.Collection.extend {
        model: Element
        url: ->
            '/section/' + @id
        initialize: ->
            @id = @_id
    }

    window.models.Element = Backbone.Model.extend {
        url: ->
            url = "/section/"
            url += if @id? then @id else ""
            url
        initialize: ->
            @set "child_els", new collections.Elements()
            @set "inFlow", true
    }

    # A list of elements which can be reordered. Basically, the overarching section architecture.
    window.views.ElementOrganizer = Backbone.View.extend({
        el: '#organize-elements'
        initialize: ->
            ### Render the list, then apply the drag and drop, and sortable functions. ###
            _.bindAll(this,"reorderCollection","render")
            @collection.on "change", @render, @
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
                if i is 0
                    $("<li/>").addClass("out-of-flow center").text("Elements Out of Flow").appendTo($el)
                itemView = new views.SortableElementItem({model: out, outOfFlow: true})
                $el.append(itemView.render().el)
        # Takes in a new index, an origin index, and an optional collection
        # When collection is ommitted, the collection uses this.collection
        reorderCollection: (newIndex, originalIndex, collection) ->
            # Get the original index of the moved item, and save the item
            collection = collection || @collection
            temp = collection.at(originalIndex)
            # Remove it from the collection
            collection.remove(temp)
            # Reinsert it at its new index
            collection.add(temp, {at: newIndex})
            # Render shit
            builder.render()
    });

    window.views.SortableElementItem = Backbone.View.extend {
        tagName: 'li class="property"'
        template: $("#element-sortable-item").html()
        initialize: ->
            that = this
            @listenTo @model, 'change', @render
            @$el.draggable {
                cancel: ".sort-element", 
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
            if @options.outOfFlow is true
                $el.addClass("out-of-flow")
            childList = $el.children(".child-list")
            that = this
            # Same recursion as draggable element. 
            _.each @model.get("child_els").models, (el) ->
                childList.append new views.SortableElementItem({model: el, child: true}).render().el
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
    }


    ### A configurable element bound to a property or page element
        Draggable, droppable, nestable. ###
    window.views.draggableElement = Backbone.View.extend({
        template: $("#draggable-element").html()
        tagName: 'div class="builder-element"'
        initialize: ->
            _.bindAll(this, "render", "bindDrop", "bindDrag", "blendModels","distance","setStyles")
            @listenTo @model, 'change', @render
            # Gets the model type
            # console.log @ instanceof views.draggableElement 
        render: ->
            that = @
            children = @model.get "child_els" 
            $el =  @$el
            # Get model layout properties and set applicable as classes
            @setStyles()
            $el.html(_.template @template, {
                property_name: @model.get "property_name"
            })
            if children?
                _.each children.models , (el) ->
                    draggable = new views.draggableElement({model: el}).render().el
                    that.$el.append(draggable)
            # Check if previous element is floated - if not, clearfix.
            if $el.prev(".builder-element").css("float") == "none"
                $el.before("<div class='clear'></div>")

            # In block rendering, next will have no effect. However, if users
            # apply layouts at different points, it will prevent float overflow
            #if $el.next(".builder-element").css("float") == "none"
             #   console.log "no next float"
              #  $el.after("<div class='clear'></div>")

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
            cancel = ".config-menu-wrap"            
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
                        console.log
                # drag: (event,ui) ->
                #     # Get the wrap element
                #     $wrap = builder.$el
                #     # Get the offset of the wrap itself
                #     $wrapoffsetT = $wrap.offset().top
                #     $wrapoffsetL = $wrap.offset().left
                #     # Get each draggable element in the builder
                #     $children = $wrap.find(".builder-element").not(event.target)
                #     # Mouse coords
                #     coords = 
                #         left: event.clientX
                #         top: event.clientY
                #     closestEl = null
                #     closestDist = null
                #     # Determine closest element to the mouse
                #     $children.each (i, el)->
                #         # Calculate the distance between the cursor and each element
                #         calc = that.distance $(el).offset(), coords
                #         # Log the minimum
                #         if (calc < closestDist) || !closestDist?
                #             closestDist = calc
                #             closestEl = el
                #     # Add feedback for user positioning
                #     # $children.css("border", "inherit")
                #     # $(closestEl).css("border-bottom","1px solid red")

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
                addTo = that.model
                # Get the model currently being dragged
                curr = builder.currentModel
                if curr.get("inFlow") is false or builder.fromSideBar is false
                    curr.set("inFlow",true)
                    # remove the clone
                    $(ui.item).remove()
                    # Lets the drag element know that it was a success
                    # This event fires before the drag stop event
                    ui.draggable.data('dropped', true)
                    ### Now, we must consolidate models ###
                    that.blendModels(curr)
                    # And finally render the newly blended parent model, with its subcollection.
                    that.render()
                else alert "That element is already in the section. Until you set duplicates to true, none are allowed."
            }
        blendModels: (dropped) ->
            # Remove the model from its current collection.
            c = dropped.collection
            if c?
                c.remove(dropped)
            wrap = @model
            # Get all current child elements, add the dropped one, and put the collection back in
            children = wrap.get "child_els"
            if children?
                wrap.set "child_els", children.add(dropped)
                organizer.render()
        events: 
            "click .config-panel" : ->
                editor = new views.ElementEditor({model: @model, view: @}).render()
            "click .set-options": (e) ->
                $t = $(e.currentTarget)
                dropdown = $t.children(".dropdown")
                dropdown.fadeToggle(100);
                e.stopPropagation()
            # So as to stop the parent list from closing
            "click .set-options li": (e) ->
                e.preventDefault()
                e.stopPropagation()
            "click .remove-from-flow": (e) ->
                self = @
                @$el.slideUp "fast", ->
                    self.remove()
                    self.model.set "inFlow", false
            "select" : (e) ->
                # Setting this property will not affect rendering immediately, so make it silent. 
                @model.set("layout-item", true, {silent: true})
            "deselect": ->
                console.log "deselecting"
                @model.set("layout-item", false, {silent: true})
    })

    window.views.SectionBuilder = Backbone.View.extend {
        el: 'section.builder-container'
        initialize: ->
            @render()
            # When a model's inFlow property changes, reRender
            @collection.on "change:inFlow", @render, @
            that = this
            $el = @$el
            $el.droppable {
                accept: 'li'
                hoverClass: "dragging"
                activeClass: "dragging" 
                tolerance: 'pointer'
                drop: ( event, ui ) -> 
                    # Children of the builder are no longer simply properties - 
                    # they are elements, which may contain properties and other 
                    # data, metadata, ui elements, et cetera.
                    curr = that.currentModel
                    # If the element is not already on the page,
                    if curr.get("inFlow") is false
                        # Render a new draggable element and append it to the list
                        temp = new views.draggableElement({model: curr}).render().el
                        # It is not in the flow again.
                        that.$el.append(temp)
                        curr.set "inFlow", true
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
                    $(".ui-selecting").addClass("selected-element"). trigger "select"
                unselecting: (e,ui) ->
                    $(".ui-unselecting").removeClass("selected-element").trigger "deselect"
                    e.stopPropagation()
                    e.preventDefault()
                    e.stopImmediatePropagation()
                selected: (e,ui) ->
                    $(".ui-selected").addClass("selected-element").trigger "select"
                    e.stopPropagation()
                    e.preventDefault()
                    e.stopImmediatePropagation()
                unselected: (e,ui) ->
                    $(".ui-unselecting").removeClass("selected-element").trigger("deselect")
                    e.stopPropagation()
                    e.preventDefault()
                    e.stopImmediatePropagation()
            }
            @currentModel = null
        render: ->
            $el = @$el
            that = this
            $el.empty()
            # Using a container appended to out of DOM, then appended to the el once
            # is preferable to appending to the el directly, as this method reduces 
            # rendering recalculation for the browser.
            container = document.createDocumentFragment()
            _.each @collection.models, (element) ->
                #If the element has been taken out of the flow, don't render it.
                if element.get("inFlow") is false
                    return
                # Even better, let's use NO jQuery. Shit is fast!
                container.appendChild(new views.draggableElement({model: element}).render().el)
            $el.append(container)
        
        setLayout: ->
            # builder = @$el 
            # length = builder.children().length
            # if length > 6
            #   length = 6
            # length = Math.floor(12 / (length % 7))
            # builder.children().removeClass().addClass('columns large-' + length)
            # $(".dropdown").hide()
    }

    # $.fn.liveDraggable = (opts) -> 
    #     $(this).delegate "div", "mouseover", ->
    #             if (!$(this).data("init")) 
    #                $(this).data("init", true).draggable(opts);
    # this
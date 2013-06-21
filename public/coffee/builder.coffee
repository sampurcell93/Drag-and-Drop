$(document).ready ->
    ### 
        MUST be bound to the window, so as not to leak into 
        global namespace and still have access to other scripts 
    ###


    window.models = {}
    window.views = {}
    window.collections = {}

    # A list of properties which can be reordered.
    window.views.PropertyOrganizer = Backbone.View.extend({
        el: '#organize-properties'
        initialize: ->
            ### Render the list, then apply the drag and drop, and sortable functions. ###
            _.bindAll(this,"sortProperties")
            @render()
            that = this
            @$el.sortable {
                axis: 'y'
                tolerance: 'touch'
                connectWith: 'ul'
                handle: '.sort-element'
                items: '> li'
                cursorAt: {top: 50}
                start: (e,ui)->
                    that.origIndex = $(ui.item).index()
                stop: (e, ui) ->
                    that.sortProperties $(ui.item).index()
            }
        render: ->
            $el = @$el
            $el.empty()
            that = this
            _.each @collection.models, (prop) ->
                itemView = new views.PropertyItem({model: prop, draggable: true, editable: false, sortable: true})
                $el.append(itemView.render().el)
        sortProperties: (newIndex) ->
            # Get the original index of the moved item, and save the item
            temp = @collection.at(@origIndex)
            # Remove it from the collection
            @collection.remove(temp)
            # Reinsert it at its new index
            @collection.add(temp, {at: newIndex})
            # Render shit
            window.builder.render()
    });


    ### A configurable element bound to a property or page element
        Draggable, droppable, nestable. ###
    window.views.draggableElement = Backbone.View.extend({
        template: $("#draggable-element").html()
        tagName: ->
            options = @options
            child = if @options.child is true then "child " else ""
            width = if options.width? then options.width  + " " else ""
            'div class="builder-element"' + child + width
        initialize: ->
            _.bindAll(this, "render", "bindDrop", "bindDrag")
        render: ->
            @$el.append(_.template @template, @model.attributes)
            @bindDrop()
            @bindDrag()
            this
        bindDrag: ->
            that = this
            cancel = ".sort-element, .set-options"            
            # if draggable element is a child of another, do not cancel on .child selection
            cancel += if @options.child then "" else ", .child"
            # Set the element to be draggable.
            @$el.draggable {
                cancel: cancel
                # When the drop is bad, do nothing
                revert: "invalid"
                # helper: "clone",
                cursor: "move"
                start: ->
                    # When a drag starts, give the builder the model so it can render on drop
                    if builder?
                        builder.currentModel = that.model
                stop: (e, ui) ->
                    # If the drop was a success, remove the original and preserve the clone
                    if ui.helper.data('dropped') is true
                        $(e.target).remove()
                    else console.log "bad drop"

            }
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
                $(e.target).removeClass("over")
                addTo = that.model
                # Get the model currently being dragged
                curr = builder.currentModel
                # Append to the draggable element
                $(e.target).append( new views.draggableElement({child: true, model: curr}).render().el )
                $(ui.item).remove()
                # Lets the drag element know that it was a success
                # This event fires before the drag stop event
                ui.draggable.data('dropped', true)
            }
        events: 
            "click .config-panel" : ->
                console.log "yolo"
            "click .set-options li": (e) ->
                e.preventDefault()
                e.stopPropagation()
            "click .set-options": (e) ->
                $t = $(e.currentTarget)
                dropdown = $t.find(".dropdown")
                dropdown.fadeToggle(100);
    })

    
    window.collections.Elements = Backbone.Collection.extend {
        model: Element
    }

    window.models.Element = Backbone.Model.extend {

    }


    window.views.SectionBuilder = Backbone.View.extend {
        el: 'section.builder-container'
        initialize: ->
            @render()
            that = this
            $el = @$el
            $el.droppable {
                accept: 'li, .child'
                hoverClass: "dragging"
                activeClass: "dragging" 
                tolerance: 'pointer'
                drop: ( event, ui ) -> 
                    # Children of the builder are no longer simply properties - 
                    # they are elements, which may contain properties and other 
                    # data, ui elements, etc.
                    prop = that.currentModel.attributes
                    newEl = new models.Element({
                        properties: prop,
                        name: prop.name
                    });
                    temp = new views.draggableElement({model: newEl}).render().el
                    that.$el.append(temp)

            }
            @currentModel = null
        render: ->
            that = this
            @$el.empty()
            _.each @collection.models, (element) ->
                if element.selected is true
                    that.$el.append(new views.draggableElement({model: element, name: element.get "name"}).render().el)
        setLayout: ->
            # builder = @$el 
            # length = builder.children().length
            # if length > 6
            #   length = 6
            # length = Math.floor(12 / (length % 7))
            # builder.children().removeClass().addClass('columns large-' + length)
            # $(".dropdown").hide()
    }

    $.fn.liveDraggable = (opts) -> 
        $("section").delegate "div", "mouseover", ->
                    if (!$(this).data("init")) 
                        $(this).data("init", true).draggable(opts);
    this
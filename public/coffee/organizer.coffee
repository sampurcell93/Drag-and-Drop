$(document).ready ->
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
                handle: '.sort-element'
                items: '> li'
                start: (e,ui)->
                    that.origIndex = $(ui.item).addClass("moving-sort").index()
                    that.collection.at(that.origIndex).trigger("sorting")
                change: (e, ui) ->
                    console.log e,ui
                    that.collection.at(that.origIndex).trigger("end-sorting")
                    that.collection.reorder $(ui.placeholder).removeClass("moving-sort").index(), that.origIndex
                    ui.item.removeClass("moving-sort")
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
                "destroy": ->
                    $el = that.$el
                "remove": (model, collection, opts) ->
                    unless (opts.organizer? and opts.organizer.itemRender is false)
                        do that.remove
                "change:title": (model) ->
                    that.$el.children(".element-title").first().text(model.get("title"))
                "change:inFlow": (model, coll, opts) ->
                    if (model.get("inFlow") is false)
                        that.$el.addClass("out-of-flow")
                    else that.$el.removeClass("out-of-flow")

            }
            @listenTo @model.get("child_els"), {
                "add": (model,collection,opts)->
                    unless (opts.organizer? and opts.organizer.itemRender is false)
                        that.append(model, opts)
            }
        render: ->
            console.log "rendering item in organizer"
            $el = @$el
            $el.html _.template @template, @model.toJSON()
            $el.draggable
                zIndex: 11111
                cancel: '.sort-element'
                revert: 'invalid'
                helper: 'clone'
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
            childList.sortable {
                items: '> li'
                axis: 'y'
                containment: 'parent'
                start: (e,ui)->
                    that.origIndex = $(ui.item).index()
                stop: (e, ui) ->
                    that.model.get("child_els").reorder $(ui.item).index(), that.origIndex
            }   
            this
        append: ( child, opts )->
            $el = @$el
            childList = $el.children(".child-list")
            elementItem = new views.SortableElementItem({model: child, index: @options.index}).render().el
            if (opts? and opts.at?) 
                if (childList.children().eq(opts.at).length)
                    childList.children().eq(opts.at).before elementItem
                else 
                    childList.append elementItem
            if child.get("inFlow") is false  
                opts.outOfFlow = true
                $el.addClass("out-of-flow")
                $("<div />").addClass("activate-element").text("m").prependTo($el)
                $("<div />").addClass("destroy-element").text("g").prependTo($el)
            childList.append elementItem
        events:
            "mousedown .sort-element": (e) ->
                @model.trigger("dragging")
            "mouseup .sort-element": (e) ->
                @model.trigger("dropped")
            "click .activate-element": (e) ->
                @model.set "inFlow", true, {e: e}
            "click .destroy-element": ->
                @model.destroy()
    }
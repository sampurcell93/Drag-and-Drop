$(document).ready ->
    # A list of elements which can be reordered. Basically, the overarching section architecture.
    window.views.ElementOrganizer = Backbone.View.extend({
        initialize: ->
            @controller = @options.controller
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find(".organize-elements")
            @collection = @options.collection
            ### Render the list, then apply the drag and drop, and sortable functions. ###
            _.bindAll(this,"append","render", "bindListeners")
            that = this

            @$el.sortable {
                axis: 'y'
                tolerance: 'touch'
                connectWith: 'ul'
                handle: '.sort-element'
                items: '> li.property'
                cancel: ".out-of-flow"
                start: (e,ui)->
                    that.oldIndex = ui.item.index() - 1
                    that.collection.at(that.oldIndex).trigger("sorting")
                stop: (e, ui) ->
                    # that.collection.at(that.origIndex)
                    that.collection.reorder $(ui.item).index() - 1, that.oldIndex, null, {opname: "Switch"}
                    # ui.item.removeClass("moving-sort")
                    ui.item.removeClass("moving-sort")
                # stop: (e, ui) ->
            }
            do @bindListeners
            @on "bindListeners", @bindListeners, @
            @
        bindListeners: ->
            @stopListening()
            that = @
            @listenTo(@collection, {
                "add": (model, collection, options) ->  
                    unless (options.organizer? and options.organizer.render is false)
                        that.append(model, options)
                "remove": ->
                    if that.collection.length is 0
                        $("<li/>").addClass("placeholder").text("No content here.").appendTo(that.$el)
            })
        render: (e) ->
            $el = @$el
            $el.children().not(".list-header, .placeholder").remove()
            that = @
            index = window.currIndex
            if @collection.length is 0 and @$(".placeholder").length is 0
                $("<li/>").addClass("placeholder").text("No content here.").appendTo(@$el)
            _.each @collection.models, (el) ->
                that.append el, {index: index, outOfFlow: false}
            @
        # Method to avoid having ot rerender an entire list on add
        append: ( element, options ) -> 
            # Because the only mechanism of sorting is the sortable ui itself,
            # no method should insert elements into the list, aside from appending at the end.
            @$el.find(".placeholder").remove()
            if options? and options.at? then @appendAt element, options
            else 
                opts = this.options
                opts.model = element
                $.extend(opts,options)
                itemView = new views.SortableElementItem(opts)
                this.$el.append(itemView.render().el)
        appendAt: (element, opts) ->
            pos = opts.at + 1
            opts.model = element
            itemView = new views.SortableElementItem(opts).render().el
            if pos >= @collection.length
                this.$el.append(itemView)
            else if pos is 1
                this.$el.children(".list-header").after(itemView)
            else 
                this.$el.children().eq(pos).before(itemView)
        events:
            "click .hide-sidebar": (e) ->
                @$el.closest(".accessories").toggleClass("hidden-sidebar")
                @$el.closest(".section-builder-wrap").last().toggleClass("no-sidebar")
                $(e.currentTarget).toggleClass("flipped")

    }); 

    window.views.SortableElementItem = Backbone.View.extend {
        tagName: 'li'
        className: 'property'
        template: $("#element-sortable-item").html()
        initialize: ->
            that = this
            # When the linked model is removed from a collection, rerender this
            # @listenTo @model, "change:inFlow", @render
            @listenTo @model,  {
                "render": @render
                "remove": (model, collection, opts) ->
                    unless (opts.organizer? and opts.organizer.itemRender is false)
                        # @$el.toggle "puff",  0, ->
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
                "remove": ->
                    if that.model.get("child_els").length is 0
                        that.$el.children(".toggle-children").hide()
                'reset': @render
            }
        render: ->
            self = @
            $el = @$el
            $el.html _.template @template, @model.toJSON()
            $el.draggable
                cancel: '.sort-element, .activate-element, .destroy-element'
                revert: 'invalid'
                helper: 'clone'
                start: (e,ui) ->
                    if (self.model.get("type") == "Property" and self.model.get("inFlow") is true)
                        clone = self.model.clone()
                        clone.collection = null;
                        children = clone.get("child_els").clone()
                        children.reset()
                        clone.set("child_els", children, {no_history: true})
                        window.currentDraggingModel = clone
                    else window.currentDraggingModel = self.model
            that = @
            # If the model is not in the page, set it aside
            if @model.get("inFlow") is false    
                @$el.addClass("out-of-flow")
            else 
                $el.removeClass("out-of-flow") 
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
            @
        append: ( child, opts )->
            $el = @$el
            $el.children(".toggle-children").show()
            if opts? and opts.at?
                @appendAt(child, opts)
                return this
            if !opts? then opts = {}
            childList = $el.children(".child-list")
            elementItem = new views.SortableElementItem({model: child, index: @options.index}).render().el
            # if child.get("inFlow") is false  
            #     opts.outOfFlow = true
            #     $el.addClass("out-of-flow")
            #     $("<div />").addClass("destroy-element").text("g").prependTo($el
            childList.append elementItem
        appendAt: (child, opts) ->
            self = @
            if $.isArray(child)
                _.each child, (model) ->
                    self.appendAt(model)
            else 
                pos = opts.at
                opts.model = child
                $el = @$el.children(".child-list")
                itemView = new views.SortableElementItem(opts).render().el
                if @model.get("child_els")? and pos >= @model.get("child_els").length - 1
                    $el.append itemView
                else if pos is 0
                    $el.prepend itemView
                else 
                    $el.children().eq(pos-1).after itemView
                    $el.children().eq(pos).before itemView
        events:
            "mousedown .sort-element": (e) ->
                @model.trigger("dragging")
            "mouseup .sort-element": (e) ->
                @model.trigger("dropped")
            "click .toggle-children": (e) ->
                @$el.children(".child-list").slideToggle "fast"
                $(e.currentTarget).toggleClass "flipped"
                e.stopPropagation()
            "click": (e) ->
                if @$el.hasClass("out-of-flow")
                    @model.set "inFlow", true, no_history: true
                e.stopPropagation()
            "click .destroy-element": (e) ->
                @model.destroy()
                e.stopPropagation()
            "mouseover": (e) ->
                @model.trigger("link-feedback")
                e.stopPropagation()
            "mouseout": (e) ->
                if !@$el.hasClass("moving-sort")
                   @model.trigger("end-feedback")
                e.stopPropagation()
    }
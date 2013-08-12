$ ->

    window.history_length = 15

    history = window.views.history = {}

    window.models.Snap = Backbone.Model.extend()

    window.collections.Snapshots = Backbone.Collection.extend 
        model: window.models.Snap 
        initialize: ->
            @detached_head = false

    history.Snapshot = Backbone.View.extend
        tagName: 'li'
        template: $("#snapshot").html()
        initialize: ->
            @controller = @options.controller
            @current = @options.current
            self = @
            @listenTo @model, {
                "aheadOfFlow": ->
                    self.$el.addClass("ahead-of-flow")
                "insideFlow": ->
                    self.$el.removeClass("ahead-of-flow")
                "destroy": ->
                    self.remove()
            }
            @
        events:
            "click": (e) -> 
                all_snaps = @model.collection
                model_index = all_snaps.indexOf(@model)
                controller  = @controller
                snapshot   = @model.get("snapshot").clone()
                $t = $ e.currentTarget
                # Get every model ahead of this one in the flow
                ahead_flow  = _.filter @model.collection.models, (m, i) ->
                    i > model_index
                inside_flow  = _.filter @model.collection.models, (m, i) ->
                    i <= model_index
                # Add a greyed out state to each model ahead of this one
                _.each ahead_flow, (snap) ->
                    snap.set("aheadOfFlow", true).trigger("aheadOfFlow")  
                # Adn remove a grey state from previous models.
                _.each inside_flow, (snap) ->
                    snap.set("aheadOfFlow", false).trigger("insideFlow")
                # Set the currentSection to the snapshot
                controller.model.set("currentSection", snapshot)
                # Bind the organizer to the snap
                controller.organizer.collection = snapshot
                controller.organizer.trigger("bindListeners")
                controller.organizer.render()
                # Bind the builder to the snap
                controller.builder.collection = snapshot
                # Link the snap to the builder
                controller.builder.scaffold.set("child_els", snapshot)
                if model_index < all_snaps.length - 1
                    all_snaps.detached_head = true
                else 
                    all_snaps.detached_head = false
                @current.oneAhead(snapshot).bindListeners()
                e.stopPropagation()
                e.stopImmediatePropagation()
                $t.addClass("selected-history").siblings().removeClass("selected-history")
                false
        render: ->
            @$el.html(_.template @template, @model.toJSON())
            @


    history.HistoryList = Backbone.View.extend
        tagName: 'div class="history-modal"'
        initialize: ->
            @controller = @options.controller
            # Refers to the list of snapshots
            @snapshots = @options.snapshots
            _.bindAll(@, "makeHistory", "render", "append", "bindListeners")
            do @bindListeners
            @
        # Add watcher to collection
        bindListeners: (collection) ->
            @stopListening()
            coll = collection || @collection
            # @Collection refers to the actual section            
            @listenTo coll, {
                # Whenever any event is fired, save the current state of the collection
                "all": @makeHistory
            }
            self = @
            _.each coll.models, (model) ->
                self.bindIndividualListener model
            @
        # Add watcher to each model in the collection
        bindIndividualListener: (model) ->
            @listenTo model, "all", @makeHistory
            @listenTo model.get("child_els"), "all", @makeHistory
            @
        # Bug fix - when the head is detached the history is linked to a collection already in the history.
        # When this snapshot is edited, the changes apply to the current state, and ALSO make a new, identical state, 
        # resulting in state duplication. This offsets the collection.
        oneAhead: (snapshot)->
            @collection = snapshot
            @ 
        makeHistory: (operation, subject, collection, options) ->
            cc "Making History."
            # By using "all" instead of delegating to the desired events,
            # we can keep parameters the same.
            ops = ["change", "add", "remove"]
            if ops.indexOf(operation) == -1 then return
            if operation == "change"
                options = collection
            if !options? then options = {}
            unless (options? and options.no_history is true)
                op = options.opname || operation
                if @snapshots.detached_head is true
                    @deleteForwardChanges()
                    @snapshots.detached_head = false
                # Copy current state
                if @controller.model.get("currentSection")?
                    clone = @controller.model.get("currentSection").clone()
                # If there was a bogus collection passed in
                if clone is false then return
                snap = new models.Snap({snapshot: clone})
                snap.set({
                    "opname": op
                    "title": subject.get "title" || null
                    "type": subject.get "type" || null
                })
                # For memory management purposes, destroy the oldest change.
                if @snapshots.length >= window.history_length
                    @snapshots.at(0).destroy({no_history: true})
                if op == "add"
                    console.log "was added"
                    @bindIndividualListener subject

                # Add that state, or snapshot, to this ocllection and
                # display it in a list of history, a la photoshop
                @snapshots.add snap
                @append snap
            @
        deleteForwardChanges: ->
            # Get all snapshots ahead of the current state
            ahead = _.filter @snapshots.models, (snap, i) ->
                snap.get("aheadOfFlow") == true
            # Destroy all of them. Woo! No garbage!
            _.each ahead, (snap) ->
                snap.destroy()
            @
        render: ->
            self = @
            @$el.empty()
            if @snapshots.length is 0
                $("<li/>").addClass("placeholder center").text("No History Here.").appendTo(@$el)
            _.each @snapshots.models, (snapshot) ->
                self.append snapshot
            @
        append: (snapshot) ->
            $el = @$el
            $el.find(".placeholder").hide()
            $el.find(".selected-history").removeClass("selected-history")
            SnapItem = new history.Snapshot({model: snapshot, controller: @controller, current: @})
            $el.append SnapItem.render().el
            $el.children().last().addClass("selected-history")
            @
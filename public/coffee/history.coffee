$ ->
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
                    cc "destroying model"
                    self.remove()
            }
        events:
            "click": (e) -> 
                all_snaps = @model.collection
                model_index = all_snaps.indexOf(@model)
                controller  = @controller
                snapshot   = @model.get("snapshot")
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
                # controller.organizer.trigger("bindListeners")
                controller.organizer.render()
                # Bind the builder to the snap
                controller.builder.collection = snapshot
                # Link the snap to the builder
                controller.builder.scaffold.set("child_els", snapshot)
                if model_index < all_snaps.length - 1
                    console.log "setting head to detached"
                    all_snaps.detached_head = true
                else 
                    all_snaps.detached_head = false
                # Set the history list's current collection to the snapshot - now ce can overwrite
                @current.collection = snapshot
                @current.bindListeners()
                e.stopPropagation()
                e.stopImmediatePropagation()
                false
        render: ->
            @$el.html(_.template @template, @model.toJSON())
            @


    history.HistoryList = Backbone.View.extend
        el: '.history ul, .history-modal'
        initialize: ->
            @controller = @options.controller
            # Refers to the list of snapshots
            @snapshots = @options.snapshots
            _.bindAll(@, "makeHistory", "copyCollection", "render", "append", "bindListeners")
            do @bindListeners
        bindListeners: ->
            @stopListening()
            # @Collection refers to the actual section
            @listenTo @collection, {
                # Whenever any event is fired, save the current state of the collection
                "all": @makeHistory
            }
        makeHistory: (operation, subject, collection, options) ->
            unless options? and options.no_history is true
                if @snapshots.detached_head is true
                    console.log "changing detached head"
                    @deleteForwardChanges()
                # Copy current state
                clone = @copyCollection(collection)
                # If there was a bogus collection passed in
                if clone is false then return
                wrapper = new models.Snap({snapshot: clone})
                wrapper.set({
                    "opname": operation
                    "title": subject.get "title" || null
                    "type": subject.get "type" || null
                })
                # Add that state, or snapshot, to this ocllection and
                # display it in a list of history, a la photoshop
                @snapshots.add wrapper
                @append wrapper
        deleteForwardChanges: ->
            # Get all snapshots ahead of the current state
            ahead = _.filter @snapshots.models, (snap, i) ->
                snap.get("aheadOfFlow") == true
            # Destroy all of them
            _.each ahead, (snap) ->
                snap.destroy()

        copyCollection: (collection) ->
            if !collection? or !collection.toJSON? then return false
            copy = new collections.Elements(collection.toJSON())
        render: ->
            self = @
            @$el.empty()
            _.each @snapshots.models, (snapshot) ->
                self.append snapshot
        append: (snapshot) ->
            $el = @$el
            SnapItem = new history.Snapshot({model: snapshot, controller: @controller, current: @})
            $el.append SnapItem.render().el
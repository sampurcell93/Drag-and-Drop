$ ->
    history = window.views.history = {}
    if !localStorage.settings? then localStorage.settings = {}
    window.settings = {
        history_length: localStorage.settings.history_length || 50
    }

    window.models.Snap = Backbone.Model.extend()

    window.collections.Snapshots = Backbone.Collection.extend 
        model: window.models.Snap 
        initialize: ->
            @detached_head = false
            snap = new models.Snap({snapshot: new collections.Elements()})
            snap.set({
                "opname": "Opened"
                "type": "Section Builder"
            })
            @add snap
            @

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
                "select": ->
                    self.$el.trigger("click")
            }
            @
        events:
            "click": (e) -> 
                # Get user's current pos on page
                # scrollheight = window.pageYOffset
                all_snaps = @model.collection
                model_index = all_snaps.indexOf(@model)
                controller  = @controller
                snapshot   = @model.get("snapshot").clone()
                @current.last_snap = @$el.siblings(".selected-history").first().index() - 1
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
                # For ctrl-z purposes, we need to save the last model that was looked at
                @current.collection = snapshot
                @current.bindListeners()
                e.stopPropagation()
                e.stopImmediatePropagation()
                $t.addClass("selected-history").siblings().removeClass("selected-history")
                false
        render: ->
            @$el.html(_.template @template, @model.toJSON())
            @

    history.HistoryList = Backbone.View.extend
        tagName: 'div'
        className: 'history-modal'
        initialize: ->
            @controller = @options.controller
            # Refers to the list of snapshots
            @snapshots = @options.snapshots
            _.bindAll(@, "makeHistory", "render", "append", "bindListeners")
            do @bindListeners
            @
        # Add watcher to collection
        # args: a collection to bind to
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
        # Args: a model to bind to
        bindIndividualListener: (model) ->
            cc "calling bindIndividualListener"
            children = model.get("child_els")
            self     = @
            @listenTo model, "change", @modelChange
            @listenTo children, "all", @makeHistory
            _.each children.models, (child) ->
                self.bindIndividualListener child
            @
        # Bug fix - when the head is detached the history is linked to a collection already in the history.
        # When this snapshot is edited, the changes apply to the current state, and ALSO make a new, identical state, 
        # resulting in state duplication. This offsets the collection.
        # args: an instance of collections.Elements
        oneAhead: (snapshot)->
            @collection = snapshot
            @ 
        selectLast: ->
            last = @last_snap
            # Shit may have been destroyed - check that the snap is still there
            if last < @snapshots.length and last >= 0
                @snapshots.at(last).trigger("select")
            @
        # Args: the model being changed, the options
        modelChange: (model, options) ->
            options = _.extend {}, options
            console.log model, options, "changed"
            unless options.no_history is true
                @deleteForwardChanges()
                snap = @takeSnapshot(options.opname || "Modified", model)
                @snapshots.add snap
                @append snap
                return @
            @
        # Called from the "all" event
        # args: the default operation title, the model being opped, [collection], [options]
        makeHistory: (operation, subject, collection, options) ->
            # By using "all" instead of delegating to the desired events,
            # we can keep parameters the same.
            # if a new model was added to a collection, listen to it as well.
            if operation == "add"
                @bindIndividualListener subject
            console.log "Storing history with operator " + operation
            ops = ["change", "add", "remove", "destroy"]
            if ops.indexOf(operation) == -1 then return
            if operation == "change"
                options = collection
            if !options? then options = {}
            unless (options? and options.no_history is true)
                op = options.opname || operation
                subject = options.subject || subject
                @deleteForwardChanges()
                # Copy current state
                snap = @takeSnapshot(op, subject)
                # Add that state, or snapshot, to this ocllection and
                # display it in a list of history, a la photoshop
                if snap isnt null
                    @snapshots.add snap
                    @append snap
                    # Scroll to bottom of history panel if overflow
                    # @$el.scrollTop(@$el.height());
            @
        # args: An opcode and the model that was being operated on
        takeSnapshot: (op, subject) ->
            # Need both in order to generate a good message
            if !subject? or !op? then return null
            if subject instanceof models.Element is true
                subject = subject.get "type"
            clone = null
            if @controller.model.get("currentSection")?
                try 
                    clone = @controller.model.get("currentSection").clone()
                catch e
                    return false
            snap = new models.Snap({snapshot: clone})
            snap.set({
                "opname": op
                "type": subject || "element"
            })
            # For memory management purposes, destroy the oldest change.
            if @snapshots.length >= window.settings.history_length and @snapshots.at(0)?
                @snapshots.at(0).destroy()
            snap
        # When the head is detached and an event occurs, delete all forwards
        # Using both filter and each because destroying models inside of each causes indexing errors
        deleteForwardChanges: ->
            if @snapshots.detached_head is true
                @snapshots.detached_head = false
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
                $("<li/>").addClass("placeholder p10 center").text("No History Here.").appendTo(@$el)
            _.each @snapshots.models, (snapshot) ->
                self.append snapshot
            @
        append: (snapshot) ->
            $el = @$el
            @$(".placeholder").hide()
            @$(".selected-history").removeClass("selected-history")
            SnapItem = new history.Snapshot({model: snapshot, controller: @controller, current: @})
            $el.prepend item = SnapItem.render().el
            $(item).addClass("selected-history")
            @
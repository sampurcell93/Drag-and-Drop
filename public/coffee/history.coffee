$ ->
    history = window.views.history = {}

    window.models.Snap = Backbone.Model.extend()

    window.collections.Snapshots = Backbone.Collection.extend 
        model: window.models.Snap 

    history.Snapshot = Backbone.View.extend
        tagName: 'li'
        template: $("#snapshot").html()
        initialize: ->
            @controller = @options.controller
        events:
            "click": -> 
                # Get the snapshot of the collection's state
                snapshot = @model.get("snapshot")
                # Set the currentSection to the snapshot
                @controller.model.set("currentSection", snapshot)
                # Bind the organizer to the snap
                @controller.organizer.collection = snapshot
                @controller.organizer.render()
                # Bind the builder to the snap
                @controller.builder.collection = snapshot
                console.log @controller.builder.scaffold
                @controller.builder.scaffold.set("child_els", snapshot)
                @controller.builder.scaffold.trigger("render")

        render: ->
            @$el.html(_.template @template, @model.toJSON())
            @


    history.HistoryList = Backbone.View.extend
        el: '.history ul'
        initialize: ->
            @controller = @options.controller
            @snapshots = @options.snapshots
            self = @
            @listenTo @collection, {
                # Whenever any event is fired, save the current state of the collection
                "all": (operation, subject, collection) ->
                    # Copy current state
                    clone = self.copyCollection(self.collection)
                    wrapper = new models.Snap({snapshot: clone})
                    wrapper.set({
                        "opname": operation
                        "title": subject.get "title"
                        "type": subject.get "type"
                    })
                    # Add that state, or snapshot, to this ocllection and
                    # display it in a list of history, a la photoshop
                    self.snapshots.add wrapper
                    self.append wrapper
            }
        copyCollection: (collection) ->
            console.log collection.toJSON()
            copy = new collections.Elements(collection.toJSON())
        render: ->
            console.log "Rdnerind ugsadvshj"
            self = @
            @$el.empty()
            _.each @snapshots.models, (snapshot) ->
                self.append snapshot
        append: (snapshot) ->
            $el = @$el
            SnapItem = new history.Snapshot({model: snapshot, controller: @controller})
            $el.append SnapItem.render().el
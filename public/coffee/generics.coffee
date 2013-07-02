$(document).ready ->

    window.models.GenericElement = Backbone.Model.extend {

    }

    window.collections.GenericElements = Backbone.Collection.extend {
        model: models.GenericElement
        url: '/generic'

    }

    window.views.GenericList = Backbone.View.extend {
        el: '.generic-elements'
        initialize: ->
            do @render
        render: ->
            $el = @$el
            _.each @collection.models, (el) ->
                $el.append new views.GenericItem({model: el}).render().el
            this
    }

    window.views.GenericItem = Backbone.View.extend {
        initialize: ->
            self = @
            @$el.draggable {
                # When the drop is bad, do nothing
                revert: "invalid"
                # Since elements are generic, the can be dragged infinitely.
                helper: "clone"
                cursor: "move"
                start: (e, ui) ->
                    $(ui.helper).addClass("dragging")
                    # Give the builder an acceptable element.
                    toAdd = new models.Element self.model.toJSON()
                    toAdd.set "child_els", new collections.Elements()
                    builder = allSections.at(sectionIndex).get("builder")
                    if builder?
                        builder.currentModel = toAdd
                        builder.fromSideBar = false
                        # Weird bug fix - need a blank log for it to register - probably coffeescript stupidity.
                        console.log
                stop: (e, ui) ->
                    $(ui.helper).removeClass("dragging")
                    # If the drop was a success, remove the original and preserve the clone
                    if ui.helper.data('dropped') is true
                        $(e.target).remove()
            }
        template: $("#generic-element").html()
        tagName: 'li'
        render: ->
            $el = @$el
            $el.html _.template @template, @model.toJSON()
            this
    }

    genericList = null
    genericCollection = new collections.GenericElements()
    genericCollection.fetch {
        success: (coll) ->
            genericList = new views.GenericList {collection: coll}
    }
$(document).ready ->

    window.existingSectionsList = null

    # This is the view for the sidebar which holds existing sections
    window.views.ExistingSectionsList = Backbone.View.extend {
        el: '#existing-sections'
        initialize: ->
            @render()
        render: ->
            $el = @$el
            _.each @collection.models, (section) ->
                console.log(section)
                section.set "inFlow", false
                $el.append new views.SingleSectionWireFrame({model: section}).render().el
    }


    # Single list item view for existing section
    window.views.SingleSectionWireFrame = Backbone.View.extend {
        tagName: 'li'
        template: $("#single-section").html()
        initialize: ->
            self = @
            @$el.draggable {
                cancel: '.view-section'
                # When the drop is bad, do nothing
                revert: "invalid"
                # helper: "clone",
                cursor: "move"
                start: (e, ui) ->
                    builder = allSections.at(sectionIndex).get("builder")
                    $(ui.helper).addClass("dragging")
                    # When a drag starts, give the builder the model so it can render on drop
                    if builder?
                        builder.currentModel = self.model
                        builder.fromSideBar = false
                        # Weird bug fix - need a blank log for it to register - probably coffeescript stupidity.
                        console.log
                stop: (e, ui) ->
                    $(ui.helper).removeClass("dragging")
                    # If the drop was a success, remove the original and preserve the clone
                    if ui.helper.data('dropped') is true
                        $(e.target).remove()
            }
        render: ->
            $el = @$el
            $el.html _.template @template, @model.toJSON()
            _.each @model.get("child_els").models, (child, i) ->
                if i < 4
                    $el.append new views.SectionThumbnail({model: child}).render().el
            this
        events: 
            "click .view-section": ->
                sectionIndex = allSections.length
                new views.SectionController()
    }

    window.views.SectionThumbnail = Backbone.View.extend {
        tagName: 'div'
        render: ->
            $el = @$el.addClass("thumb-object")
            styles = @model.get "styles"
            if styles?
                @$el.css styles
            _.each @model.get("child_els").models, (child, i) ->
                console.log child
                if i < 4
                    $el.append new views.SectionThumbnail({model: child}).render().el
            this
    }

    # We can think of a section as a collection of elements, so this pulls each collection from the database.
    sectionCollection = new collections.Elements()
    sectionCollection.fetch {
        success: (coll) ->
            # Once the sections are pulled, generate the list.
            existingSectionsList = new views.ExistingSectionsList { collection : sectionCollection }
    }
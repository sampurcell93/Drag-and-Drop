$(document).ready ->

    window.existingSectionsList = null

    # This is the view for the sidebar which holds existing sections
    window.views.ExistingSectionsList = Backbone.View.extend {
        initialize: ->
            @controller = @options.controller
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = $(".control-section").eq(@controller.index).find(".existing-sections-layouts")
            @el = @$el.get()
            @render()
        render: ->
            $el = @$el
            console.log @collection.models, @$el, @controller.index
            console.log 
            _.each @collection.models, (section) ->
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
                coll = new collections.Elements()
                _.each @model.get("currentSection"), (obj) ->
                    model = new models.Element(obj)
                    model.set("child_els", model.modelify model.get("child_els"))
                    coll.add model
                @model.set("currentSection", coll)
                @model.set("properties", new collections.Properties(@model.get("properties")))
                console.log @model.get "currentSection"
                allSections.add @model
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
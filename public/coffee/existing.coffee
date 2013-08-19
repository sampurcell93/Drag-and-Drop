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
            self = @
            _.each @collection.models, (section, i) ->
                if i == 0
                    self.$(".placeholder").remove()
                $el.append new views.SingleSectionWireFrame({model: section}).render().el
    }


    # Single list item view for existing section
    window.views.SingleSectionWireFrame = Backbone.View.extend {
        tagName: 'li'
        template: $("#single-section").html()
        initialize: ->
            @makeModel()
            self = @
            @$el.draggable {
                cancel: '.view-section'
                # When the drop is bad, do nothing
                revert: "invalid"
                helper: "clone",
                cursor: "move"
                start: ->
                    window.copiedModel = self.model.get("currentSection").models
                stop: (e, ui) ->
                    $(ui.helper).removeClass("dragging")
                    # If the drop was a success, remove the original and preserve the clone
                    if ui.helper.data('dropped') is true
                        $(e.target).remove()
            }
        makeModel: ->
            section = @model.get("currentSection")
            properties = @model.get("properties")
            @model.set("properties", new collections.Properties(properties))
            copy = new collections.Elements()
            _.each section, (model) ->
                el = new models.Element(model)
                copy.add el.deepCopy()
            @model = new models.SectionController({
                currentSection: copy,
                properties: @model.get("properties"),
                section_title: @model.get("section_title"),
                title: @model.get("title")
            })
            copy
        render: ->
            $el = @$el
            $el.html _.template @template, @model.toJSON()
            @
        events: 
            "click": ->
                allSections.add @model
    }

    window.views.ElementThumbnail = Backbone.View.extend {
        tagName: 'div'
        className: 'thumb-object'
        initialize: (opts) ->
            @model = opts
        render: ->
            $el = @$el
            styles = @model.styles
            if styles?
                @$el.css styles
            _.each @model.child_els, (child, i) ->
                $el.append new views.ElementThumbnail({model: child}).render().el
            @
    }
$(document).ready ->


    # Store the display type of the element, and a string reference to its view type
    # This view type also refers to the editor template, stored in editors.coffee within the
    # window.views.editors object.
    generics = [
        {
            "type" : "Button",
            "view" : "Button",
        },
        {
            "type" : "Custom Text",
            "view" : "CustomText"
        },
        {
            "type" : "Custom Header",
            "view" : "CustomHeader"
        },
        # {
        #     "tagName" : "ol",
        #     "type" : "Numbered List",
        #     "view" : "listElement",
        #     listItems: [1,2,3]
        # },
        # {
        #     "tagName" : "ul",
        #     "type" : "Bulleted List",
        #     "view" : "listElement",
        #     listItems: [1,2,3]
        # },
        {
            type: 'Date/Time'
            view: 'DateTime'
        },
        {
            type: 'Radio'
            view: 'Radio'
        },
        {
            type: 'Link'
            view: 'Link'
        },
        {
            type: 'Dropdown'
            view: 'Dropdown'
        },
    ]

    window.models.GenericElement = Backbone.Model.extend {}

    window.collections.GenericElements = Backbone.Collection.extend {
        model: models.GenericElement
        url: '/generic'

    }

    window.views.GenericList = Backbone.View.extend {
        el: ".generic-elements ul"
        initialize: ->
            @controller = @options.controller
            @collection = new collections.GenericElements(generics)
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find(".generic-elements ul")
            @el = @$el.get()
            do @render
        render: ->
            $el = @$el
            _.each @collection.models, (el) ->
                $el.append new views.OutsideDraggableItem({model: el}).render().el
            this
    }

    window.views.OutsideDraggableItem = Backbone.View.extend {
        initialize: ->
            # need to preserve default state of genericity
            baseModel = @model.toJSON()
            self = @
            @$el.draggable {
                # When the drop is bad, do nothing
                revert: true
                # Since elements are generic, the can be dragged infinitely.
                helper: "clone"
                    # $(new window.views[self.model.get("view")]({model: self.model}).render().el).css("width","500px")
                cursor: "move"
                start: (e, ui) ->
                    $(ui.helper).addClass("dragging")
                    child_els = new collections.Elements()
                    toAdd = new models.Element(baseModel)
                    child_els.model = toAdd
                    toAdd.set("child_els", child_els)
                    # Give the builder an acceptable element.
                    window.currentDraggingModel = toAdd
                    console.log toAdd is self.model
                stop: (e, ui) ->
                    $(ui.item).removeClass("dragging").remove()
                    # If the drop was a success, remove the original and preserve the clone
                    if ui.helper.data('dropped') is true
                        $(e.target).remove()
            }
        template: $("#generic-element").html()
        tagName: 'li'
        render: ->
            $el = @$el.addClass("generic-item")
            $el.html _.template @template, @model.toJSON()
            this
    }

    class window.views.genericElement extends window.views.draggableElement
        # Calls the parent initialize function - mimicry of classical inheritance.
        initialize: (options) -> 
            super
            $.extend(@events, {
                # When they edit an input, update the model's display title.
                "keyup .title-setter": (e) ->
                    @model.set('title', $(e.currentTarget).val(), {no_history: true})
                    e.stopPropagation()
            })

    # For clarity's sake, we will store the variety of generic templates and their
    # event binders with hash notation. View specifications can be stored on server.
    # Each generic view is an extension of the ultimate generic view - that is, an element
    # which is draggable (see builder.js/coffee) There are too many events and cases to 
    # store in a single class,so we'll split it up here using inheritance.
    # HANG ON - javascript does INHERITANCE????????!

    class views["Property"] extends views.genericElement
        template: $("#property-template").html()
        className: 'builder-element block'


    class window.views['Button'] extends window.views.genericElement
        template: $("#button-template").html()
        initialize: (options) ->
            super
            self = @
            # Using .on() is bad because in certain cases, listeners are not unbound.
            # .listenTo() not working for now
            @model.on "change:title", (model) ->
                self.$el.children(".title-setter").text(model.get("title"))


    class window.views['CustomHeader'] extends window.views.genericElement
        template: $("#custom-header").html()
        initialize: (options) ->
            super

    class window.views['CustomText'] extends window.views.genericElement
        template: $("#custom-text").html()
        className: 'builder-element w5'

    class window.views['Radio'] extends window.views.genericElement
        template: $("#generic-radio").html()
        initialize: (options) ->
            super 
            @model.on {
                "change:label_position" : @render
                "change:label_text" : @render
            }


    class window.views['Link'] extends window.views.genericElement
        template: $("#custom-link").html()
        initialize: (options) ->
            super 

    class window.views['DateTime'] extends window.views.genericElement
        template: $("#date-time").html()
        initialize: (options) ->
            _.bindAll(@, "afterRender")
            super 
        afterRender: ->
            @$el.find(".date-picker").datepicker()

    class window.views['Dropdown'] extends window.views.genericElement
        template: $("#dropdown").html()
        initialize: (options) ->
            super 
    class window.views['TableCell'] extends window.views.genericElement
        tagName: 'td class="builder-element"'
        initialize: (options) ->
            super 

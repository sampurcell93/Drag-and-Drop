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
            type: 'Input Field'
            view: "Input"
        }
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
            @
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
                    $(ui.helper).addClass("dragging").data("opname", "create")
                    # child_els = new collections.Elements()
                    drag = new models.Element baseModel
                    toAdd = drag.deepCopy()
                    # child_els.model = toAdd
                    # toAdd.set("child_els", child_els)
                    # Give the builder an acceptable element.
                    window.currentDraggingModel = toAdd
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
        events: 
            "click": ->
                child_els = new collections.Elements()
                toAdd = new models.Element(@model.toJSON())
                child_els.model = toAdd
                toAdd.set("child_els", child_els, {no_history: true})
                console.log allSections.at(window.currIndex)
                cc allSections.at(window.currIndex).get("builder").scaffold.blend toAdd, at: 0, opname: 'create'
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
            self = @
            @model.on "change:title", (model) ->
                self.$el.find(".label-text").first().text(self.model.get("title"))

    # For clarity's sake, we will store the variety of generic templates and their
    # event binders with hash notation. View specifications can be stored on server.
    # Each generic view is an extension of the ultimate generic view - that is, an element
    # which is draggable (see builder.js/coffee) There are too many events and cases to 
    # store in a single class,so we'll split it up here using inheritance.
    # HANG ON - javascript does INHERITANCE????????!

    class views["Input"] extends views.genericElement
        template: $("#input-template").html()
        className: 'builder-element w5'
        initialize: ->
            super
            self = @
            @model.on "change:editable", ->
                self.render()


    class window.views['Button'] extends window.views.genericElement
        template: $("#button-template").html()


    class window.views['CustomHeader'] extends window.views.genericElement
        template: $("#custom-header").html()


    class window.views['CustomText'] extends window.views.genericElement
        template: $("#custom-text").html()

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

    class window.views['DateTime'] extends window.views.genericElement
        template: $("#date-time").html()
        initialize: (options) ->
            _.bindAll(@, "afterRender")
            if typeof @model.get("display") == "undefined"
                @model.set("display", "full", {silent: true})
            super 
        afterRender: ->
            @$(".date-picker").first().datepicker()

    class window.views['Dropdown'] extends window.views.genericElement
        template: $("#dropdown").html()

    class window.views['TableCell'] extends window.views.genericElement
        tagName: 'td class="builder-element"'
$(document).ready ->

    window.models.GenericElement = Backbone.Model.extend {
        defaults: ->
            listItems: [1,2,3]
    }

    window.collections.GenericElements = Backbone.Collection.extend {
        model: models.GenericElement
        url: '/generic'

    }

    window.views.GenericList = Backbone.View.extend {
        initialize: ->
            @controller = @options.controller
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find(".generic-elements")
            console.log @controller.index
            do @render
        render: ->
            $el = @$el
            _.each @collection.models, (el) ->
                $el.append new views.GenericListItem({model: el}).render().el
            this
    }

    window.views.GenericListItem = Backbone.View.extend {
        initialize: ->
            # need to preserve default state of genericity
            @baseModel = @model.toJSON()
            self = @
            @$el.draggable {
                # When the drop is bad, do nothing
                revert: true
                # Since elements are generic, the can be dragged infinitely.
                helper: "clone"
                cursor: "move"
                zIndex: 999999
                start: (e, ui) ->
                    $(ui.helper).addClass("dragging")
                    # Give the builder an acceptable element.
                    toAdd = $.extend({}, self.model.toJSON())
                    console.log toAdd
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
            $el = @$el
            $el.html _.template @template, @model.toJSON()
            this
    }

    window.views.genericElement = window.views.draggableElement.extend
        afterRender: (self) ->
            self.$el.hide().fadeIn(350)
        initialize: ->
            $.extend @events, 
                # When they edit an input  for a header update the model
                "keyup .title-setter": (e) ->
                    console.log(@)
                    @model.set {
                        'customHeader': $(e.currentTarget).val()
                        'title': $(e.currentTarget).val()
                    }
                    e.stopPropagation()
    # For clarity's sake, we will store the variety of generic templates and their
    # event binders with hash notation. View specifications can be stored on server.
    # Each generic view is an extension of the ultimate generic view - that is, an element
    # which is draggable (see builder.js/coffee) There are too many events and cases to 
    # store in a single class,so we'll split it up here using inheritance.
    # HANG ON - javascript does INHERITANCE????????!
    window.views['listElement'] = window.views.genericElement.extend
        template: $("#generic-list").html()
        initialize: ->
            $.extend this.events, 
                # Append a new dummy list item to the scaffold
                "click .add-list-item":  (e) ->
                    genericList = @$el.find(".generic-list")
                    index = genericList.children().length
                    innerText = "Item " + (index + 1)
                    $("<li/>").text(innerText).attr("contenteditable", true).appendTo(genericList)
                    @model.updateListItems(innerText, index)
                    e.stopPropagation()
                "keyup .generic-list li": (e) ->
                    keyCode = e.keyCode || e.which
                    target = $(e.currentTarget)
                    index = target.index()
                    if target.index() is 0
                        @model.set("title", target.text())
                    @model.updateListItems(target.html(), index)
                "click .remove-property-link": (e) ->
                    $(e.currentTarget).closest(".property-link").slideUp "fast", ->
                    $(this).remove()
    window.views['Button'] = window.views.genericElement.extend
        template: $("#button-template").html()
        initialize: ->
            # Key line which binds all parent views to this, the descendant!
            _.bindAll(@, "beforeRender")
        beforeRender: (self) ->
            @$el.addClass("max-w3")

    window.views['CustomHeader'] = window.views.genericElement.extend
        template: $("#custom-header").html()

    window.views['CustomText'] = window.views.genericElement.extend
        template: $("#custom-text").html()
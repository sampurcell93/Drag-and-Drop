$(document).ready ->

    allLayouts =[
        {
            type: 'Dynamic Layout'
            view: 'dynamicLayout'
        },
        {
            type: 'Dynamic Container'
            view: 'dynamicContainer'
        },
        {
            type: 'Tabs'
            view: 'tabs'
        },
        {
            type: 'Accordion'
            view: 'accordion'
        }
    ]
    class window.models.Layout extends window.models.Element


    window.collections.Layouts = Backbone.Collection.extend {
        model: models.Layout          
    } 

    window.views.LayoutList = Backbone.View.extend {
        el: ".layout-types ul"
        template: $("#picker-interface").html()
        initialize: ->
            @controller = @options.controller
            @collection = new collections.Layouts(allLayouts)
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find(@el)
            @el = @$el.get()
            do @render
        render: ->
            $el = @$el
            _.each @collection.models, (layout) ->
                $el.append new views.GenericListItem({model: layout}).render().el
            this
    }        

    class window.views["dynamicLayout"] extends window.views["genericElement"]
        template: $("#dynamic-layout").html()
        initialize: ->
            _.bindAll @, "afterRender"
            super
        afterRender: ->

    class window.views["dynamicContainer"] extends window.views["genericElement"]
        template: $("#dynamic-container").html()
        initialize: ->
            _.bindAll @, "afterRender"
            super
        afterRender: ->


    class window.views["accordion"] extends window.views["genericElement"]
        template: $("#accordion-layout").html()
        initialize: ->
            _.bindAll @, "afterRender"
            @listenTo @model.get("child_els"), 'add', (m,c,o) ->
                console.log "added, overwrite"
            super
        afterRender: ->
            if (@model.get("child_els").length)
                @$el.children(".placeholder").remove()

    class window.views["tabs"] extends window.views["genericElement"]
        template: $("#tab-layout").html()
        initialize: ->
            _.bindAll @, "afterRender"
            super
        afterRender: ->
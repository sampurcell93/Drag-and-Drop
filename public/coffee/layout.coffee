$(document).ready ->
   window.collections.Layouts = Backbone.Collection.extend {
        url: '/layout'
        initialize: ->
            self = @
            @fetch {
                success: ->
                    window.layoutList = new views.LayoutList {collection: self}
            }
   } 

   window.models.Layout = Backbone.Model.extend {}

   window.views.LayoutItem = Backbone.View.extend {
        tagName: 'li'
        template: $("#layout-item").html()
        render: ->
            @$el.html(_.template @template, @model.toJSON())
            this
        events:
            "click": (e)->
                $(e.target).toggleClass("selected-layout").siblings().removeClass("selected-layout")
                window.layoutList.selected = @model
   }
   window.views.LayoutList = Backbone.View.extend {
        tagName: 'div class="modal"'
        template: $("#picker-interface").html()
        initialize: ->
            _.bindAll this, "render"
            @render()
        render: ->
            self = @
            $el = @$el
            $el.append _.template @template, {}
            _.each @collection.models, (layout) ->
                $el.find(".layout-list").append(new views.LayoutItem({model: layout}).render().el)
            $(document.body).addClass("active-modal").append($el)
        events: 
            'click .try-layout': ->
                if !@selected? 
                    alert "you must choose a layout"
                else
                    @applyLayout(currentSection)
        applyLayout: (collection) ->
            styling = @selected.get "styling"
            _.each collection.models, (el) ->
                # Only apply layout to selected models.
                if el.get("layout-item") is true    
                    el.set("styles", styling)
   }        

   window.layoutList = null
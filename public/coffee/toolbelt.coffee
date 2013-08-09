$ ->
    toolbelt = window.views.toolbelt = {}

    class toolbelt.Actives extends Backbone.View
        el: ".quick-props"
        initialize: ->
            @listenTo @model, "change", @quickAttrs
            @listenTo @model.get "child_els", "change", @quickAttrs

        render: ->
            @quickAttrs()
        getProps: (attrs) ->
            property_item = "<li><%=prop.clean() %>: <%= value %></li>";
            properties = ""
            for prop of attrs
                unless @disregardAttrs.indexOf(prop) != -1
                    properties +=  _.template property_item, {
                        prop: prop
                        value: @formatAttributes(attrs[prop])
                    }
            properties
        disregardAttrs: ["inFlow", "view", "styles", "property"]
        quickAttrs: (e) ->
                if @$el.hasClass("builder-scaffold") then return false
                properties = "<ul>"
                attrs = @model.attributes
                properties += @getProps(attrs)
                properties += "</ul>"   
                $(".quick-props").find("ul").html(properties)
        formatAttributes: (data) ->
            if (typeof data == "string")
                return data
            else if $.isArray(data)
                items = ""
                if data.length is 0 then return "None"
                _.each data, (item) ->
                    items += "<span style='color: red'>" + item + "</span>"
                return items
            else 
                return @formatObject(data.models)
        formatObject: (obj) ->
            if !obj? then return ""
            self = @
            items = "<div class='close-arrow pointer'>p</div><ul class='hidden'>"
            if obj.length is 0 then return "None"
            _.each obj, (model) ->
                items += "<li>" + self.getProps(model.attributes) + "</li>"
            items += "</ul>"
            items

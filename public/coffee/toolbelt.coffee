$ ->
    toolbelt = window.views.toolbelt = {}

    class toolbelt.Actives extends Backbone.View
        tagName: 'ul'
        render: ->
            @quickAttrs()
            @
        getProps: (attrs) ->
            property_item = "<li data-attr='<%=prop%>'><%=prop.clean() %>: <%= value %></li>";
            properties = ""
            for prop of attrs
                unless @regard.indexOf(prop) == -1
                    properties +=  _.template property_item, {
                        prop: prop
                        value: @formatAttributes(attrs[prop])
                    }
            properties
        regard: ["child_els", "title", "type"]
        editables: ["title"]
        quickAttrs: (e) ->
                if @$el.hasClass("builder-scaffold") then return false
                attrs = @model.attributes
                properties = @getProps(attrs)
                @$el.html(properties)
        formatAttributes: (data) ->
            if (typeof data == "string")
                return "<span contentEditable>" + data + "</span>"
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
            items = "<div class='close-arrow icon-uniF48A'></div><ul class='hidden'>"
            if obj.length is 0 then return "None"
            _.each obj, (model) ->
                items += "<li>" + self.getProps(model.attributes) + "</li>"
            items += "</ul></div>"
            items
        events: 
            "keyup [data-attr] span": (e) ->
                $t   = $ e.currentTarget
                attr = $t.closest("[data-attr]").data("attr")
                val  = $t.html()
                @model.set attr, val, {no_history: true}
                e.stopPropagation()
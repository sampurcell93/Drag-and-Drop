$ ->
    # This was written in like three minutes - forgive the lack of templating. TODO: fix
    toolbelt = window.views.toolbelt = {}

    class toolbelt.Actives extends Backbone.View
        tagName: 'ul'
        initialize: ->
            self = @
            @listenTo @model, {
                "change": (model, opts) ->
                    console.log model
                "remove": @remove
            }
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
            properties += "<div class='view-full-config'>View Full Configuration</div>"
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
            items = "<ul class='hidden'>"
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
            "click .view-full-config": ->
                @model.trigger("showConfigModal")
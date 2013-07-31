$ ->
    editors = window.views.editors = {}

    # The editor will NOT display changes live. Instead, each action which would affect a model
    # will be added to a queue. The queue will be executed when the changes are submitted, or discarded otherwise.

    class editors["BaseEditor"] extends Backbone.View
        change_queue: []
        tagName: "div class='modal'"
        initialize: ->
            # To avoid concatenation of extra templates onto child class,
            # don't call "super", and overwrite the function
            if @templates? then @templates = @templates.concat [$("#skins").html(), $("#column-picker").html()]
            else @templates = [$("#skins").html(), $("#column-picker").html()]
        render: ->
            # A pointer to the linked element in the builder.
            self     = @
            @link_el = @options.link_el 
            cq       = @change_queue
            editor_content  = ""
            # This is not optional, the controls must be there
            if @templates? 
                @templates = @templates.concat [$("#finalize-editing").html()]
            # template data, and append results to the element.
            _.each @templates, (template) ->
                editor_content += _.template template, self.model.toJSON()
            # Append editor to body - making it a true modal is not within the purvue of this class
            @$el.appendTo(document.body).html(editor_content)

        events:
            "click [data-columns]": (e) ->
                coltypes = ["two", "three", "four", "five", "six"]
                $t       = $ e.currentTarget
                cols     = $t.data("columns")
                self     = @

                if @model?
                    @change_queue["classes-columns"] = ->
                        self.model.set "columns", cols
                _.each coltypes, (type) ->
                    $(self.link_el).removeClass("column " + type)
                unless cols == ""
                    $(self.link_el).addClass("column " + cols)

            # On confirm, execute every item in the queue, then render the view again
            # Perhaps queue is misleading.... try hashtable. Repetitive events do not need to
            # bu pushed over and over.... just assign them a unique title.
            "click .confirm": ->
                cq = @change_queue
                # Fuck yeah, closures.
                for process of cq
                    do cq[process]
                @model.trigger("render")
            # On confirm or reject, close the modal.
            "click .reject, .confirm": ->
                $(document.body).removeClass("active-modal")
                do @remove


    class editors["Button"] extends editors["BaseEditor"]
        templates: [$("#button-editor").html()]
        initialize: ->
            self = @
            $.extend @events, {
                "keyup .title-setter": ->
                    self.cq["title"] = ->
                        self.model.set("title", self.$el.find(".title-setter").val())
            }
        render: ->
            super
            @cq = @change_queue
            modal = @el || $(".modal").first()
            @$el = $(@el)
    class editors["accordion"] extends editors["BaseEditor"]
        templates: [$("#accordion-layout").html()]
    # new editors["Button"]().render()
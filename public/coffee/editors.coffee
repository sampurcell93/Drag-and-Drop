$ ->
    editors = window.views.editors = {}

    # The editor will NOT display changes live. Instead, each action which would affect a model
    # will be added to a queue. The queue will be executed when the changes are submitted, or discarded otherwise.

    class editors["BaseEditor"] extends Backbone.View
        change_queue: []
        tagName: "div class='modal'"
        standards: [
            $("#change-styles").html()
        ]
        initialize: ->
            if !@templates? then @templates = []
            @templates = @templates.concat @standards
        render: ->
            if !@templates?
                @templates = []
            # A pointer to the linked element in the builder.
            self     = @
            @link_el = @options.link_el 
            editor_content  = ""
            # This is not optional, the controls must be there 
            @templates = @templates.concat [$("#finalize-editing").html()]
            # template data, and append results to the element.
            _.each @templates, (template) ->
                editor_content += _.template template, self.model.toJSON()
            # Append editor to body - making it a true modal is not within the purvue of this class
            @$el.appendTo(document.body).html(editor_content)
        # Put a new event into the queue, executed only if the user clicks .confirm
        enqueue: (name, func) ->
             @change_queue[name] = func
        events:
            "change .set-width": (e) ->
                width = $(e.currentTarget).val()
                self = @
                console.log 
                @enqueue("width-change", ->
                    $(self.link_el).addClass(width)
                    classes = self.model.get "classes"
                    classes.push width
                    self.model.set("classes", classes)
                )
            "keyup .title-setter": ->
                self = @
                @enqueue("title", ->
                    self.model.set("title", self.$el.find(".title-setter").val(), { no_history: true })
                )
            "click .confirm": ->
                cq = @change_queue
                # Fuck yeah, closures.
                for process of cq
                    process = do cq[process]
            # On confirm or reject, close the modal.
            "click .reject, .confirm": ->
                $(document.body).removeClass("active-modal")
                do @remove

    class editors["BaseLayoutEditor"] extends editors["BaseEditor"]
        # Put in order to reflect the order they are appended in. Tab functionality... later.
        standards: [
            $("#layout-changer").html()
            $("#skins").html(),
            $("#column-picker").html()
        ]
        initialize: ->
            if !@templates? then @templates = []
            @templates = @templates.concat @standards
            _.extend @events, {
                "click [data-columns]": (e) ->
                    coltypes = ["two", "three", "four", "five", "six"]
                    $t       = $ e.currentTarget
                    cols     = $t.data("columns")
                    self     = @
                    $t.addClass("selected-choice").siblings().removeClass("selected-choice")
                    if @model?
                        @enqueue("columns", ->
                            self.model.set "columns", cols
                            classes = self.model.get "classes"
                            classes.push("column " + cols) 
                            self.model.set "classes", classes
                        )
                    _.each coltypes, (type) ->
                        self.enqueue("remove_col_classes-" + type, ->
                            $(self.link_el).removeClass("column " + type)
                        )
                    unless cols == ""
                        @enqueue("add_col_classes", ->
                            $(self.link_el).addClass("column " + cols)
                        )
                "click [data-layout]": (e) ->
                    $t      = $ e.currentTarget
                    layout  = $t.data("layout")
                    self    = @
                    $t.addClass("selected-choice").siblings().removeClass("selected-choice")
                    @enqueue("view", ->
                        self.model.set({
                            "layout": true
                            "view": layout
                            type: "Tab Layout"
                        })
                        $(self.link_el).addClass("tab-layout")
                    )

            # On confirm, execute every item in the queue, then render the view again
            # Perhaps queue is misleading.... try hashtable. Repetitive events do not need to
            # bu pushed over and over.... just assign them a unique title. Potential problems:
            # need order of ops. Solution: use a conditional upsert. TODO
            }

    class editors["Button"] extends editors["BaseEditor"]
        templates: [$("#button-editor").html()]
        render: ->
            super
            @cq = @change_queue
            modal = @el || $(".modal").first()
            @$el = $(@el)
    class editors['Link'] extends editors["BaseEditor"]
        templates: [$("#link-editor").html()]
        initialize: ->

    class editors['Radio'] extends editors["BaseEditor"]
        templates: [$("#radio-editor").html()]
        initialize: ->
            self = @
            _.extend @events, {
                "change .label-position": (e) ->
                    position = $(e.currentTarget).val()
                    self.enqueue("label_position", ->
                        self.model.set("label_position", position)
                    )
                "keyup .label-text": (e) ->
                    label = $(e.currentTarget).val()
                    self.enqueue("label_text", ->
                        self.model.set("label_text", label)
                    )
            }

    class editors["accordion"] extends editors["BaseLayoutEditor"]
        templates: [$("#accordion-layout").html()]
    # new editors["Button"]().render()
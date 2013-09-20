$ ->
    editors = window.views.editors = {}

    # The editor will NOT display changes live. Instead, each action which would affect a model
    # will be added to a queue. The queue will be executed when the changes are submitted, or discarded otherwise.

    class editors["BaseEditor"] extends Backbone.View
        change_queue: []
        className: 'modal'
        # TODO: change the format of editor templates to be arrays of objects. In this way
        #, each object and its templates can represent a single tab in the editor.
        templates: [
            # Standard elements, can be concatenated to with the addTemplate function.
            # Each object in the array represents a tab, the tab property defines its name
            # and the templates array defines its content.
            {
                tab: 'Element Styling'
                templates: [
                    $("#change-styles").html()
                ]
            }
        ]
        render: ->
            # A pointer to the linked element in the builder.
            self     = @
            @link_el = @options.link_el 
            editor_content  = "<ul class='tabs'>"
            templates = @instance_templates || @templates
            tabs = _.pluck templates, "tab"
            _.each tabs, (tab, i) ->
                if i == 0 then sel = "current-tab"
                else sel = ""
                editor_content += "<li class='" + sel + "' rel='" + tab.dirty() + "'>" + tab + "</li>"
            editor_content += "</ul>"
            _.each templates, (tabcontent, i) ->
                editor_content += "<div class='modal-tab' id='" + tabcontent.tab.dirty() + "'>"
                _.each tabcontent.templates, (template) ->
                    editor_content += _.template template, self.model.toJSON()
                editor_content += "</div>"
                true
            # This is not optional, the controls must be there 
            editor_content += _.template $("#finalize-editing").html(), {}
            @$el.appendTo(document.body).html(editor_content)
        # Put a new event into the queue, executed only if the user clicks .confirm
        enqueue: (name, func) ->
             @change_queue[name] = func
        # A helper function for adding templates anywhere in the tab architecture.
        # Args: the template to be added, the tab index you want it at, and 
        # optionally the index within that tab
        addTemplate: (template, index, inner_index) ->
            if !@instance_templates? then return false
            cc "Adding a template"
            if !inner_index?
                @instance_templates[index].templates.push template
            else
                @instance_templates[index].templates.splice inner_index, 0, template
            console.log @instance_templates
            true
        # Pass in a tab object of form { tab: 'Title', templates: [...]}, index optional.
        addTab: (obj, index) ->
            if !@instance_templates? then return false
            if index?
                @instance_templates.splice index, 0, obj
            else 
                @instance_templates.push obj
            true
        events:
            "change [data-attr]": (e) ->
                $t   = $ e.currentTarget
                attr   = $t.data "attr"
                val    = $t.val()
                self   = @
                parsed = val.parseBool()

                if parsed == null then parsed = val
                @enqueue(attr, ->
                    self.model.set(attr, parsed)
                )
                e.stopPropagation()

            "change .set-width": (e) ->
                width = $(e.currentTarget).val()
                self = @
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
                @change_queue = []
                do @remove
            "click .tabs li": (e) ->
                $t = $ e.currentTarget
                $el = @$el
                rel = "#" + $t.attr "rel"
                @$(".modal-tab").not(rel).hide()
                $(rel).show()
                $t.addClass("current-tab").siblings().removeClass("current-tab")

    class editors["BaseLayoutEditor"] extends editors["BaseEditor"]
        # Put in order to reflect the order they are appended in. Tab functionality... later.
        templates: [
            {
                tab: 'Free Form Divisions'
                templates: [
                    $("#column-picker").html()
                ]
            }
            {
                tab: 'Preset Layouts'
                templates: [
                    $("#layout-changer").html()
                    $("#skins").html()
                    $("#preset-layouts").html()
                ]
            }
        ]
        initialize: ->
            self = @
            _.extend @events, {
                "click .select-one li": (e) ->
                    $(e.currentTarget).addClass("selected-choice").siblings().removeClass("selected-choice")

                "click [data-columns]": (e) ->
                    coltypes = ["two", "three", "four", "five", "six"]
                    $t       = $ e.currentTarget
                    cols     = $t.data("columns")
                    if self.model?
                        self.enqueue("columns", ->
                            self.model.set "columns", cols
                            classes = self.model.get "classes"
                            classes.push("column " + cols) 
                            self.model.set "classes", classes
                            console.log "applying column to ", self.model
                        )
                    self.enqueue("remove_col_classes", ->
                        $(self.link_el).removeClass("column two three four five six")
                    )
                    unless cols == ""
                        @enqueue("add_col_classes", ->
                            $(self.link_el).addClass("column " + cols)
                        )
                "click [data-layout]": (e) ->
                    $t      = $ e.currentTarget
                    layout  = $t.data("layout")
                    @enqueue("view", ->
                        self.model.set({
                            "layout": true
                            "view": layout
                            type: "Tab Layout"
                        })
                        $(self.link_el).addClass("tab-layout")
                    )
                "click .preset-layouts li": (e) ->
                    $t = $ e.currentTarget
                    className = $t.data("class")
                    self = @
                    @enqueue("presetlayout", ->
                        self.model.set("presetlayout", className)
                        $(self.link_el).addClass(className).removeClass("column two three four five six")
                    )


            # On confirm, execute every item in the queue, then render the view again
            # Perhaps queue is misleading.... try hashtable. Repetitive events do not need to
            # bu pushed over and over.... just assign them a unique title. Potential problems:
            # need order of ops. Solution: use a conditional upsert. TODO
            }

    class editors["Button"] extends editors["BaseEditor"]
        initialize: ->
            super
            # Because in the prototype model, modifying the parent modifies all descendants, we 
            # must create a copy of the base template set and modify that.
            @instance_templates = @templates.clone()
            console.log @instance_templates == @templates
            @addTemplate($("#button-editor").html(), 0)
    class editors['Link'] extends editors["BaseEditor"]
        templates: [$("#link-editor").html()]
        initialize: ->

    class editors['Radio'] extends editors["BaseEditor"]
        templates: [$("#radio-editor").html()]
        initialize: ->
            super
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
                        self.model.set("title", label)
                    )
            }

    class editors["DateTime"] extends editors["BaseEditor"]
        templates: [$("#icon-or-full").html()]

    class editors["Property"] extends editors["BaseEditor"]
        templates: [$("#property-editor").html()]

    class editors["accordion"] extends editors["BaseLayoutEditor"]
        templates: [$("#accordion-layout").html()]
    # new editors["Button"]().render()
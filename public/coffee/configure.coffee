$(document).ready ->
    # Since we'll be storing all open sections in a collection, we 
    # can refer to them by their indices in the collection. Alternatively,
    # we could construct a hastable by title, but that could lead to collissions
    # when titles overlap.
    window.sectionIndex = window.currIndex = 0

    ###################
    ##### MODELS ######ƒ
    ###################

    # IE Customer
    window.models.DataType = Backbone.Model.extend({
        url: ->
            "/class/"
    });

    # A single property - pulled from the db with only a name, but returned to a new section
    # with many more options configured.
    window.models.Property = Backbone.Model.extend {}

    ###################
    ### COLLECTIONS ###
    ###################

    window.collections.AllSections = Backbone.Collection.extend {
        model:  models.SectionController
    }

    # Collection of all properties being used in the section.
    window.collections.Properties = Backbone.Collection.extend {
        model: models.Property
    }

    # Collection of all classes in the system
    window.collections.ClassList = Backbone.Collection.extend({
        url: "/class",
        model: models.DataType
    })

    # A central hub which binds other data
    window.allSections = new collections.AllSections()

    ###################
    ###### VIEWS ######
    ###################


    ### IMPORTANT: Order of oparations: Model generated blank, added to collection of sections ->
        View generated on blank template, rendered ->
        Model populated, elements like builder rendered and linked to their els, made
        possible by rendering the view first.
    ###

    window.views.SectionControllerView = Backbone.View.extend {
        tagName: 'div'
        wrap: '.section-builder-wrap'
        template: $("#controller-wrap").html()
        initialize:->
            self = @
            @listenTo @model, {   
                "change:title": (model)->
                    self.$el.find(".section-title").text(model.get("title"))
                "destroy": ->
                    self.remove()
            }
        render: ->
            @$el.addClass("control-section").html _.template @template, @model.toJSON()
            $(".container").droppable
                accept: '.builder-element, .draggable-modal'
                drop: (e, ui) ->
                    models = window.currentDraggingModel
                    if !models? then return false
                    if $.isArray(models) is true
                        ui.helper.remove()
                        _.each models, (model) ->
                            model.set("inFlow", false)
                    else 
                        models.set("inFlow", false)
            this
        events: 
            'click .generate-section': 'generateSection'
            'click .save-section': 'saveSection'
            'click .view-layouts': ->
                window.layoutCollection = new collections.Layouts()
            'click .view-sections': (e)->
                $(e.currentTarget).toggleClass("active")
                $("#existing-sections").animate({height: 'toggle'}, 200)
            'click .configure-interface': ->
                @model.get("builder").$el.toggleClass("no-grid")
            'click .section-title': (e) ->
                self = @
                modal = window.launchModal(_.template($("#section-change").html(), {title: @model.get("title")}) + "<button class='confirm m10'>Ok</button>")
                modal.delegate(".change-section-title", "keyup", ->
                    $t = $ this
                    title =  $t.val()
                    if title == "" then title = $t.data("previous-val") || "Default Title"
                    self.model.set "title", title
                )
                e.stopPropagation()
                e.stopImmediatePropagation()
            'focus .section-title': (e) ->
                $(e.currentTarget).data("previous-val", $(e.currentTarget).val())
            'blur .section-title': (e) ->
                $t = $(e.currentTarget)
                if ($t.val() == "")
                    $t.val($t.data("previous-val") || "")
            'click .history': (e)->
                @$el.find(".history-modal").slideToggle("fast")
            "click .settings": ->
                temp = $("#settings-template").html()
                modal = window.launchModal(_.template temp, window.settings)
                modal.find(".hist-length").slider({
                    value: window.settings.history_length
                    step: 1
                    min: 0
                    max: 100
                    change: (e, ui) ->
                        window.settings.history_length = ui.value
                        localStorage.settings.history_length = ui.value
                        $(".history-length-label").text(ui.value)

                })
        setProps: ->
            console.log "starting setprops, currIndex is %d", currIndex
            that = @
            if !opts? 
                opts = {}
            @model.index = allSections.length - 1 
           
             # We can think of a section as a collection of elements, so this pulls each collection from the database.
            @existingSectionCollection = new collections.Elements()
            @existingSectionCollection.fetch {
                success: (coll) ->
                    # Once the sections are pulled, generate the list.
                    that.existingSectionsList = new views.ExistingSectionsList {collection : coll, controller: that.model }
            }
            section = @model.get("currentSection")
            @snaps = new collections.Snapshots()
            @histList = new views.history.HistoryList({
                controller: @
                snapshots: @snaps
                collection: section
            })

            # The controller now has a reference to the builder
            @builder = new views.SectionBuilder({
                controller: @model
                collection: section
            })
            # Link this controller to the scaffolding - which is linked to the collection itself.
            # Through this narrow channel, the controller gains access to the architecture of the section,
            # and also to the intricacies of the build.
            @organizer = new views.ElementOrganizer {
                controller: @model
                collection: section
            }

            $o_el = @$el.find(".accessories")
            hist_modal = window.launchDraggableModal(@histList.render().el, null, $o_el, "History - Recent <span class='history-length-label'>15</span>")
            hist_modal.addClass("history")

            props_modal = window.launchDraggableModal($("<ul/>"), null, $o_el, "Editable Attributes")
            props_modal.addClass("quick-props")

            css_modal = window.launchDraggableModal($("<ul/>"), null, $o_el, "Skin Format")
            css_modal.addClass("quick-css")

            $o_el.droppable
                accept: '.moved'
                greedy: true
                out: (e,ui) ->
                    ui.draggable.addClass("moved")
                drop: (e,ui) ->
                    ui.draggable.css({"position": "relative"}).removeClass("moved")

            # All classes
            @classes =  new collections.ClassList({controller: @model})
            @classes.fetch({
                success: (coll) ->
                    that.dataview = new views.DataView({collection: coll, controller: that.model})
                    that.selectedData = new views.SelectedDataList({collection: that.model.get("properties"), controller: that.model})
                failure: ->
                    alert("could not get data from URL " + that.url)    
            })

            @genericList = new views.GenericList {controller: @model}
            @layouts = new views.LayoutList({ controller: @model })
            @model.set({
                builder: @builder
                organizer: @organizer
                snaps: @snaps
                controller: @
            })
            @

        renderComponents: (components) ->
            for component in components
                this[component].render()
            @model.saved = true
        generateSection: (e) ->
            if e?
                $t = $(e.currentTarget)
                $t.toggleClass "viewing-layout"
            @$el.find(@wrap).slideToggle('fast')
        saveSection: ->
            title = @model.get "title"
            if title == "" or typeof title is "undefined" or title == "Default Section Title"
                alert "You need to enter a title"
                return false
            # _.each @model.get("currentSection").models, (model) ->
            #     model.unset "inFlow", {silent: true}
            copy = new models.SectionController()
            copy.set({
                currentSection: @model.get("currentSection")
                section_title: title
                properties: @model.get("properties")
            })
            @model.saved = true
            copy.save(null, {
                success: ->
                    $("<div />").addClass("modal center").html("You saved the section").appendTo(document.body);
                    $(document.body).addClass("active-modal")
                    $(".modal").delay(2000).fadeOut "fast", ->
                        $(@).remove()
                        $(document.body).removeClass("active-modal")
            })
            true
    }

    window.views.AllSectionControllers = Backbone.View.extend {
        el: '.container',
        initialize: ->
            self = @
            @render()
            @listenTo @collection, "add", (model) ->
                self.append(model)
        render: ->
            $el = @$el
            $el.empty()
            self = @
            _.each @collection.models, (controller, i) ->
                self.append(controller)
            this
        append: (model) ->
            window.currIndex = @collection.length - 1
            view = new views.SectionControllerView({model: model})
            @$el.append($(view.render().el))
            view.setProps().renderComponents(["builder","organizer"])
            @
    }

    window.views.SectionTabItem = Backbone.View.extend {
        template: $("#tab-item").html(),
        tagName: 'li'
        initialize: ->
            @listenTo(@model, "change:title", @render)
        render: (i) ->
            if (typeof i == "string" or typeof i == "number")
                @$el.attr("data-id",i)
            @$el.html _.template @template, {title: @model.get "title"}
            @$el.droppable {
              tolerance: 'pointer'
              accept: '.builder-element'
              over: (e, ui) ->
                # Give the droppable some feedback
                $t = $(e.target).addClass("over")
                checkHover = ->
                    clone = $(ui.item).clone()
                    if $t.hasClass("over")
                        $t.trigger("click")
                        toSection = $(".control-section").eq(window.currIndex).find(".generate-section")
                        if !toSection.hasClass("viewing-layout")
                            toSection.trigger("click")
                window.setTimeout(checkHover,500)
              out: (e)->
                $(e.target).removeClass("over")
              drop: (e,ui) ->   

            }
            this
        events: 
            "click .remove": (e) ->
                if @model.saved is true
                    @model.destroy()
                else 
                    sure = confirm("Are you sure you want to close this builder? You haven't saved it.")
                    if sure is true
                        @model.destroy()
                    else return

                index = @$el.index() - 1
                collection = @model.collection
                # If you're closing the tab you're on
                if index == window.currIndex
                    if index + 1 < collection.length
                        @$el.next().trigger("click")
                    else if index - 1 >= 0
                        @$el.prev().trigger("click")
                    else window.currIndex = 0
            "click": (e) ->
                window.currIndex = @$el.index() - 1
                $t = $(e.currentTarget)
                index = $t.addClass("current-tab").data("id")
                $t.siblings().removeClass("current-tab")
                $(".control-section").hide()
                $(".control-section").eq(window.currIndex).show()
    }

    window.views.SectionTabs = Backbone.View.extend {
        el: ".tabs"
        initialize: ->
            @listenTo @collection, {"add": @render, "remove": @render }
            @render()
        render: ->
            $el = @$el
            # Remove all children but the control element
            $el.children().not(".add-section").remove()
            len = allSections.models.length
            _.each allSections.models, (section, i) ->
                tab =  new views.SectionTabItem({ model: section }).render(i).el
                $el.append tab
                if i == len - 1
                    $(tab).hide().animate({"width":"show"}, 300).addClass("current-tab").trigger("click")
        events: 
            "click .add-section": (e) ->
                allSections.add new models.SectionController()

    }

    # A View wrapper with functions that manipulate all instance data. There shall be no
    # data declared in the window other than prototypes - all instances shall be linked
    # via the controller.

    window.models.SectionController = Backbone.Model.extend {
        url: '/section'
        defaults: ->
            "currentSection":  new collections.Elements()
            "properties":  new collections.Properties()
        initialize: ->
            @saved = true
            self = @
            @get("currentSection").on "all", ->
                self.saved = false
            @on "all", ->
                self.saved = false
    }

    # A View of all Classes
    window.views.DataView = Backbone.View.extend({
        initialize: ->
            @controller = @options.controller
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find(".class-list")
            _.bindAll(this,'render')
            @render()
        render: ->
            that = @
            @$el.empty()
            _.each(this.collection.models, (prop, i) ->               
                unless prop.rendered
                    prop.rendered = true;
                    that.$el.append new views.DataSingle({model: prop, index: that.controller.index}).render().el
            )
        events: 
            "click .new-data-type": ->
                mod = new DataType {name: 'Private', properties: []}
                @collection.add(mod)
                @ender()
    });

    # A Single Class, with controls for adding properties
    window.views.DataSingle = Backbone.View.extend({
        template: $("#data-type").html(),
        updateTemplate: $("#add-property").html()
        tagName: 'li'
        initialize: ->
            _.bindAll(this,'render')
        render: ->
            $el = $(@el)
            $el.prepend _.template @template, @model.toJSON()
            props = @model.get "properties"
            # Loop through all properties returned by the datatype, and create a model for each.
            for prop, i in props
                newProperty = new models.Property(prop)
                newProperty.set("className", @model.get("name"))
                # Then append a new view for that model
                $el.append new views.PropertyItem({model: newProperty, index:@options.index, editable: false}).render().el
            # allSections.at(@options.index).get("snaps").reset()
            this
        events:
            "click .add-property": (e) ->
                newProp = new models.Property({name: 'Change Me', className: @model.get("name")})
                @$el.append prop = new views.PropertyItem({model: newProp, index: @options.index, editable: true}).render().el
                # allSections.at(@options.index).get("properties").add newProp
            "click .close": (e) ->
                that = @
                $(e.currentTarget).closest("li").fadeOut "fast", ->
                    $(this).remove()
                    that.model.destroy()
            "click .hide-properties": (e) ->
                $t = $(e.currentTarget)
                $t.children(".icon").toggleClass("flipped")
                $t.siblings("li").fadeToggle("fast")
    })

    # A list of all the properties a user wants in their application view.
    window.views.SelectedDataList = Backbone.View.extend({
        template: $("#configure-property").html()
        initialize: ->
            @controller = @options.controller
            @wrapper = $(".control-section").eq(@controller.index)
            @$el = @wrapper.find(".property-editor")
            @listenTo @collection,  {
                "add": @append
            }
            _.bindAll(this,'render')
            @render()
        render: ->
            $el = @$el
            self = @
            _.each  @collection.models, (prop) ->
                self.append(prop)
        append: (prop) ->
            @$el.append new views.PropertyItemEditor({model: prop}).render().el
    })

    # An editing bar where a user may configure the logic of the particular view.
    window.views.PropertyItemEditor = Backbone.View.extend({
        template: $("#property-item-editor").html()
        tagName: 'li'
        initialize: ->
            self = @
            @listenTo @model, {
                "remove": ->
                    self.$el.fadeOut "fast", ->
                        do self.remove
                "change:name": @render
            }
        render: ->
            @$el.html _.template @template, @model.toJSON()
            this
    })

    # A list item which a user may select by clicking, 
    # in order to add it to their application view.
    window.views.PropertyItem = Backbone.View.extend({
        template: $("#property-item").html()
        tagName: 'li class="property" '
        render: ->
            item = $.extend({}, @model.toJSON(), @options)
            @$el.append(_.template @template,item)
            # .toggleClass("selected").find("input").trigger "click"
            # @chooseProp()
            this
        chooseProp: (e) ->
            if e?
                $t = $(e.currentTarget)
                $t.closest(".property").toggleClass "selected"
            selected = @model.selected
            currentSection = allSections.at(@options.index).get("currentSection")
            @model.selected = if selected then false else true
            if @model.selected is true
                allSections.at(@options.index).get("properties").add @model
                model = @model.toJSON()
                model.title = model.className + "." + model.name
                # model.property = {}
                model.view = "Property"
                model.property = @model
                model.property.name = model.name
                model.type = "Property"
                if !@elementModel?
                    @elementModel = new models.Element(model)
                currentSection.add @elementModel
            else 
                allSections.at(window.currIndex).get("properties").remove @model
                currentSection.remove @elementModel
        events:
            "click .choose-prop": "chooseProp"
            "keyup": (e) ->
                $t =  $(e.currentTarget)
                # Get the new name of the property
                val = $t.text()
                # Set the model name
                @model.set("name", val)
    })
    allSections.add new models.SectionController()
    window.sectionTabs = new views.SectionTabs({collection: allSections})
    window.sectionList = new views.AllSectionControllers({collection: allSections})

    ctrlDown = false
    ctrlKey  = 17
    vKey     = 86
    cKey     = 67

    # When a user presses the ctrl key, enter "command mode"
    $(@).keydown (e) ->
        keyCode = e.keyCode || e.which
        if keyCode == ctrlKey then ctrlDown = true

    # When they go up, 
    $(@).keyup (e) ->
        keyCode = e.keyCode || e.which
        if keyCode == ctrlKey
            ctrlDown = false
        if keyCode == 90 and ctrlDown is true
            snaps = allSections.at(window.currIndex).toJSON().controller.histList
            snaps.selectLast()

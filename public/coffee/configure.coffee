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
            @listenTo @model, "change:title", (model)->
                self.$el.find(".section-title").text(model.get("title"))
        render: (i) ->
            @$el.addClass("control-section").attr("id","section-" + i).html _.template @template, @model.toJSON()
            @$el.droppable
                accept: '.builder-element'
                drop: (e, ui) ->
                    models = window.currentDraggingModel
                    if $.isArray(models) is true
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
        setProps: ->
            that = this
            if !opts? 
                opts = {}
            @model.index = allSections.length - 1 
            # Render page scaffolding
            @snaps = new collections.Snapshots()
            @histList = new window.views.history.HistoryList({
                controller: @
                snapshots: @snaps
                collection: @model.get("currentSection")
            })

            # The controller now has a reference to the builder
            @builder = new views.SectionBuilder({
                controller: @model
                collection: @model.get("currentSection")
            })
            # Link this controller to the scaffolding - which is linked to the collection itself.
            # Through this narrow channel, the controller gains access to the architecture of the section,
            # and also to the intricacies of the build.
            @organizer = new views.ElementOrganizer {
                controller: @model
                collection: @model.get("currentSection")
            }
            # All classes
            @classes =  new collections.ClassList({controller: @model})
            @classes.fetch({
                success: (coll) ->
                    that.dataview = new views.DataView({collection: coll, controller: that.model})
                    that.selectedData = new views.SelectedDataList({collection:that.model.get("properties"), controller: that.model})
                failure: ->
                    alert("could not get data from URL " + that.url)    
            })

            @genericList = new views.GenericList {controller: @model}

            @layouts = new views.LayoutList({ controller: @model })
            @model.set({
                builder: @builder
                organizer: @organizer
                snaps: @snaps
            })
            this

        renderComponents: (components) ->
            for component in components
                this[component].render()
        generateSection: (e) ->
            if e?
                $t = $(e.currentTarget)
                $t.toggleClass "viewing-layout"
                if $t.hasClass "viewing-layout"
                    $t.text "View Configuration" 
                else $t.text "View Section Builder"
            @$el.find(@wrap).slideToggle('fast')
        saveSection: ->
            title = @$el.find(".section-title").text()
            if title == "" or typeof title is "undefined" or title == "Default Section Title"
                alert "You need to enter a title"
                return
            # _.each @model.get("currentSection").models, (model) ->
            #     model.unset "inFlow", {silent: true}
            copy = new models.SectionController()
            copy.set({
                currentSection: @model.get("currentSection")
                section_title: title
                properties: @model.get("properties")
            })
            copy.save(null, {
                success: ->
                    $("<div />").addClass("modal center").html("You saved the section").appendTo(document.body);
                    $(document.body).addClass("active-modal")
                    $(".modal").delay(2000).fadeOut "fast", ->
                        $(@).remove()
                        $(document.body).removeClass("active-modal")
            })
    }

    window.views.AllSectionControllers = Backbone.View.extend {
        el: '.container',
        initialize: ->
            self = @
            @render()
            @listenTo @collection, "add", (e) ->
                self.append(e)
        render: ->
            $el = @$el
            $el.empty()
            self = @
            _.each @collection.models, (controller, i) ->
                self.append(controller)
            this
        append: (model) ->
            view = new views.SectionControllerView({model: model})
            @$el.append($(view.render(@collection.models.length - 1).el))
            view.setProps().renderComponents(["builder","organizer"])
            this
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
              revert: 'invalid'
              accept: '.builder-element'
              over: (e, ui) ->
                # Give the droppable some feedback
                $t = $(e.target).addClass("over")
                checkHover = ->
                    clone = $(ui.item).clone()
                    if $t.hasClass("over")
                        $t.trigger("click")
                        toSection = $(".control-section").eq(currIndex).find(".generate-section")
                        if !toSection.hasClass("viewing-layout")
                            toSection.trigger("click")
                window.setTimeout(checkHover,500)
              out: (e)->
                $(e.target).removeClass("over")
              drop: (e,ui) ->   

            }
            this
        events: 
            "mouseover": (e) ->
                @hovering = true
                self = @
                window.setTimeout( ->
                    if self.hovering is true
                        $(self.el).find(".remove").fadeIn("fast")
                        e.stopPropagation()
                        e.stopImmediatePropagation()
                , 400)
            "mouseleave": ->
                @hovering = false
                @$el.find(".remove").fadeOut("fast")
            "click": (e) ->
                window.currIndex = @$el.index() - 1
                $t = $(e.currentTarget)
                index = $t.addClass("current-tab").data("id")
                $t.siblings().removeClass("current-tab")
                $(".control-section").hide()
                $("#section-" + index).delay(200).show()
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
                    currIndex = 1
                    $(tab).hide().animate({"width":"show"}, 300).addClass("current-tab").trigger("click")
        events: 
            "click .add-section": (e) ->
                sectionIndex += 1
                allSections.add new models.SectionController()
                e.stopImmediatePropagation()
                $(".control-section").hide()
                $("#section-" + sectionIndex).show()

    }

    # A View wrapper with functions that manipulate all instance data. There shall be no
    # data declared in the window other than prototypes - all instances shall be linked
    # via the controller.

    window.models.SectionController = Backbone.Model.extend {
        url: '/section'
        defaults: ->
            "currentSection":  new collections.Elements()
            "properties":  new collections.Properties()

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
            console.log "TesT"
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
                allSections.at(@options.index || currIndex).get("properties").remove @model
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

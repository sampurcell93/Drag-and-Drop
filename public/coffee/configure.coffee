$(document).ready ->
	# Since we'll be storing all open sections in a collection, we 
	# can refer to them by their indices in the collection. Alternatively,
	# we could construct a hastable by title, but that could lead to collissions
	# when titles overlap.
	window.sectionIndex = 0

	###################
	##### MODELS ######ƒ
	###################

	# IE Customer
	window.models.DataType = Backbone.Model.extend({
		url: ->
			"/class/"
	});

	window.models.ElementWrapSaver = Backbone.Model.extend {
		url: "/section",
		toJSON: ->
			@attributes.model.toJSON()
	}

	# Stores an entire instance of a section controller as a model
	window.models.Interface = Backbone.Model.extend()

	# A single property - pulled from the db with only a name, but returned to a new section
	# with many more options configured.
	window.models.Property = Backbone.Model.extend({
	})

	###################
	### COLLECTIONS ###
	###################

	window.collections.AllSections = Backbone.Collection.extend {
		model: 	models.Interface
	}

	# A central hub which binds other data
	window.allSections = new collections.AllSections()

	# Collection of all properties being used in the section.
	window.collections.Properties = Backbone.Collection.extend {
		model: models.Property
	}

	# Collection of all classes in the system
	window.collections.ClassList = Backbone.Collection.extend({
		url: "/class",
		model: models.DataType,
		initialize: (options) ->
			@controller = options.controller
			that = @
			@fetch({
				success: ->
					dataview = new views.DataView({collection: that})
					selectedData = new views.SelectedDataList({collection: that.controller.get("properties")})
				failure: ->
					alert("could not get data from URL " + that.url)	
			})
			this
	})

	###################
	###### VIEWS ######
	###################

	# A View wrapper with functions that manipulate all instance data. There shall be no
	# data declared in the window other than prototypes - all instances shall be linked
	# via the controller.
	window.views.SectionController = Backbone.View.extend {
		el: '.control-section'
		wrap: '.section-builder-wrap'
		template: $("#controller-wrap").html()
		initialize: ->
			# Render page scaffolding
			@render()
			@index = allSections.length
			# Make a new, empty collection of elements.
			@collection = new collections.Elements()
			# The controller now has a reference to the builder
			@builder = new views.SectionBuilder({
				collection: @collection, 
				index: @index
			})
			# Link this controller to the scaffolding - which is linked to the collection itself.
			# Through this narrow channel, the controller gains access to the architecture of the section,
			# and also to the intricacies of the build.
			@organizer = new views.ElementOrganizer {
				collection: @collection
				index: @index
				builder: @builder
			}
			# Collection of all selected properties
			@properties = new collections.Properties({index: @index})
			@interface = new models.Interface {
				currentSection: @collection
				builder: @builder
				organizer: @organizer
				properties: @properties
			}
			allSections.add @interface
			# All classes
			@classes = new collections.ClassList({controller: @interface})
		render: ->
			@$el.html _.template @template, {}
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
   				@builder.$el.toggleClass("no-grid")

		generateSection: (e) ->
			if e?
				$t = $(e.currentTarget)
				$t.toggleClass "viewing-layout"
				if $t.hasClass "viewing-layout"
					$t.text "View Configuration" 
					@organizer.render()
					@builder.render()
				else $t.text "View Section Builder"
			$(@wrap).slideToggle('fast')
		saveSection: ->
			title = $("#section-title").val()
			if title == ""
				alert "You need to enter a title"
				return
			_.each @collection.models, (model) ->
				model.set "section_name", title
				model.unset "inFlow", {silent: true}
			el = new models.ElementWrapSaver({model:@collection})
			el.save(null, {
				success: ->
					$("<div />").addClass("modal center").html("You saved the section").appendTo(document.body);
					$(document.body).addClass("active-modal")
					$(".modal").delay(2000).fadeOut "fast", ->
						$(@).remove()
						$(document.body).removeClass("active-modal")
			})
	}



	# A View of all Classes
	window.views.DataView = Backbone.View.extend({
		el: '#class-list'
		initialize: ->
			_.bindAll(this,'render')
			@render()
		render: ->
			that = @
			_.each(this.collection.models, (prop) ->
				unless prop.rendered
					prop.rendered = true;
					$(that.el).append new views.DataSingle({model: prop}).render().el
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
				# Then append a new view for that model
				$el.append new views.PropertyItem({model: newProperty}).render().el
			this
		events:
			"click .add-property": (e) ->
				newProp = new models.Property({name: 'Change Me'})
				$(@el).append new views.PropertyItem({model: newProp}).render().el
				allSections.at(sectionIndex).get("properties").add newProp
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
		el: '.property-editor'
		template: $("#configure-property").html()
		initialize: ->
			@listenTo @collection, "add", @render
			_.bindAll(this,'render')
			@render()
		render: ->
			$el = $(@el)
			$el.empty()
			_.each  @collection.models, (prop) ->
				$el.append new views.PropertyItemEditor({model: prop}).render().el
				this
	})

	# An editing bar where a user may configure the logic of the particular view.
	window.views.PropertyItemEditor = Backbone.View.extend({
		template: $("#property-item-editor").html()
		tagName: 'li'
		render: ->
			$(@el).append _.template @template, @model.toJSON()
			this
	})

	# A list item which a user may select by clicking, 
	# in order to add it to their application view.
	window.views.PropertyItem = Backbone.View.extend({
		template: $("#property-item").html()
		tagName: ->
			# If the properties are stored as selected, mark the view as such.
			selected = if @model.selected is true then "selected" else ""
			id = if @options.sortable is true then allSections.at(sectionIndex).get("properties").indexOf(@model) else ""
			'li class="property ' + selected + '" data-prop-id="' + id + '"'
		render: ->
			@$el.append _.template @template, @model.toJSON()
			if Math.random() > .6
				@selected = true
				@$el.trigger "click"
			this
		events:
			"click": (e) -> 
				$t = $(e.currentTarget)
				$t.toggleClass "selected"
				selected = @model.selected
				currentSection = allSections.at(sectionIndex).get("currentSection")
				@model.selected = if selected then false else true
				if @model.selected is true
					allSections.at(sectionIndex).get("properties").add @model
					model = @model.toJSON()
					model.title = model.name
					model.linkage = model
					if !@elementModel?
						@elementModel = new models.Element(model)
					currentSection.add @elementModel, {silent: true }
				else 
					allSections.at(sectionIndex).get("properties").remove @model
					currentSection.remove @elementModel
					if builder?
						builder.render()
			"keyup": (e) ->
				$t =  $(e.currentTarget)
				# Get the new name of the property
				val = $t.find("div").text()
				# Set the model name
				@model.set("name", val)
	})

	# Initialize the controller, as a sort of "brain"
	sectionController = new views.SectionController()

$(document).ready ->
	# View of all data types
	dataview = null
	# All selected properties
	selectedData = null
	# A central hub which binds other data
	sectionController = null

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
	window.models.Property = Backbone.Model.extend({
		initialize: ->
			# randomized testing
			if Math.random() > .6
				@selected = true
				properties.add @
	})

	window.models.Element = Backbone.Model.extend {

	}

	###################
	### COLLECTIONS ###
	###################

	# Collection of all properties being used in the section.
	window.collections.Properties = Backbone.Collection.extend {
		initialize: ->
			@on("remove", ->
				console.log "removing element from collection"
			)
		swapItems: (index1, index2) ->
			temp = @models[index1]
			@models[index1] = @models[index2]
			@models[index2] = temp
		
		model: models.Property
	}

	# Collection of all classes in the system
	window.collections.ClassList = Backbone.Collection.extend({
		url: "/class",
		model: models.DataType,
		initialize: ->
			that = this
			@fetch({
				success: ->
					dataview = new views.DataView({collection: that})
					selectedData = new views.SelectedDataList({collection: properties})
					sectionController = new views.SectionController()
				failure: ->
					alert("could not get data from URL " + that.url)	
			})
			this
	})

	###################
	###### VIEWS ######
	###################

	# A View wrapper with functions that manipulate the other data.
	window.views.SectionController = Backbone.View.extend {
		el: '.control-section'
		wrap: '.section-builder-wrap'

		initialize: ->
			@selected = properties
			# @generateSection()
		events: 
			'click .generate-section': 'generateSection'
		generateSection: (e) ->
			if e?
				$t = $(e.currentTarget)
				$t.toggleClass "viewing-layout"
				if $t.hasClass "viewing-layout"
					$t.text "View Configuration" 
				else $t.text "View Section Builder"
			$(@wrap).slideToggle('fast')
			window.builder = new views.SectionBuilder({collection: @selected})
			@organizer = new views.PropertyOrganizer({collection: @selected})
	}

	# A View of all Classes
	window.views.DataView = Backbone.View.extend({
		el: '#class-list'
		initialize: ->
			_.bindAll(this,'render')
			@render()
		render: ->
			that = this
			_.each(this.collection.models, (prop) -> 
				unless prop.rendered
					prop.rendered = true;
					$(that.el).append new views.DataSingle({model: prop}).render().el
			)
		events: 
			"click .new-data-type": ->
				mod = new DataType {name: 'Private', properties: []}
				this.collection.add(mod)
				this.render()
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
			$el.prepend _.template @template, @model.attributes
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
				properties.add(newProp)
			"click .close": (e) ->
				that = this
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
			$(@el).append _.template @template, @model.attributes
			this
	})

	# A list item which a user may select by clicking, 
	# in order to add it to their application view.
	window.views.PropertyItem = Backbone.View.extend({
		template: $("#property-item").html()
		tagName: ->
			# If the properties are stored as selected, mark the view as such.
			selected = if @model.selected is true then "selected" else ""
			id = if @options.sortable is true then properties.indexOf(@model) else ""
			'li class="property ' + selected + '" data-prop-id="' + id + '"'
		render: ->
			that = this
			item = @model.attributes;
			for opt, i of @options
				item[opt] = i
			if @options.draggable is true
				@$el.draggable {
			        cancel: ".sort-element", 
			        revert: "invalid", 
			        helper: "clone",
			        cursor: "move",
			        start: ->
			        	if window.builder?
			        		window.builder.currentModel = that.model
		        }
			$(@el).append _.template @template, item
			this
		events:
			"click": (e) -> 
				$t = $(e.currentTarget)
				$t.toggleClass "selected"
				selected = @model.selected
				@model.selected = if selected then false else true
				if @model.selected is true
					properties.add @model
				else 
					properties.remove @model
				selectedData.render()
			"keyup": (e) ->
				$t =  $(e.currentTarget)
				# Get the new name of the property
				val = $t.find("div").text()
				# Set the model name
				@model.set("name", val)
				# Render the selection list
				selectedData.render()
	})

	# A list of all selected properties.
	properties = new collections.Properties()

	elements = new collections.Elements()

	# Call the collection and render the page.
	classes = new collections.ClassList()
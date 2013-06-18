$(document).ready ->
	# IE Customer
	DataType = Backbone.Model.extend({
		url: ->
			c = "/class/"
		initialize: ->
			this.set("selected", [])
	});
	dataview = null
	selectedData = null
	# A List of all Classes
	DataView = Backbone.View.extend({
		el: '#class-list'
		initialize: ->
			_.bindAll(this,'render')
			console.log(@collection)
			@render()
		render: ->
			that = this
			_.each(this.collection.models, (prop) -> 
				unless prop.rendered
					prop.rendered = true;
					$(that.el).append new DataSingle({model: prop}).render().el
			)
		events: 
			"click .new-data-type": ->
				mod = new DataType {name: 'Private', properties: []}
				this.collection.add(mod)
				this.render()
	});

	SelectedDataList = Backbone.View.extend({
		el: '.property-editor'
		template: $("#configure-property").html()
		initialize: ->
			_.bindAll(this,'render')
			@render()
		render: ->
			$el = $(@el)
			$el.empty()
			_.each this.collection.models, (dataType) ->
				selected = dataType.get "selected"
				props = dataType.get "properties"
				for sel, i in selected 
					if sel? and i?
						$el.append props[i]
				this
	})

	PropertyItemEditor = Backbone.View.extend({
		template: $("#property-item-editor").html()
	})

	PropertyItem = Backbone.View.extend({
		template: $("#property-item").html()
	})

	Property = Backbone.Model.extend({
		initialize: ->
			console.log this
	})

	# A Single Class
	DataSingle = Backbone.View.extend({
		template: $("#data-type").html(),
		updateTemplate: $("#add-property").html()
		tagName: 'li'
		initialize: ->
			_.bindAll(this,'render')
		render: ->
			$el = $(@el)
			$el.prepend _.template @template, @model.attributes
			props = @model.get "properties"
			for prop, i in props
				$el.append prop
			this
		events:
			"click .property": (e) -> 
				$t = $(e.currentTarget)
				prop = parseInt $t.data "property"
				$t.toggleClass "selected"
				selected = @model.get("selected")
				selected[prop] = if selected[prop] then false else true
				@model.set 'selected', selected

				selectedData.render()
			"click .add-property": (e) ->
				$(this.el).find("ul").append _.template @updateTemplate, {}
			"click .close": (e) ->
				$(e.currentTarget).closest("li").fadeOut "fast", ->
					$(this).remove()
			"click .hide-properties": (e) ->
				$t = $(e.currentTarget)
				$t.children(".icon").toggleClass("flipped")
				$t.siblings("ul").slideToggle("fast")
	})



	ClassList = Backbone.Collection.extend({
		url: "/class",
		model: DataType,
		initialize: ->
			that = this
			@fetch({
				success: ->
					dataview = new DataView({collection: that})
					selectedData = new SelectedDataList({collection: that})
				failure: ->
					alert("could not get data from URL " + that.url)	
			})
			this
	})

	classes = new ClassList()
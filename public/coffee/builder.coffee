$(document).ready ->
	### 
		MUST be bound to the window, so as not to leak into 
		global namespace and still have access to other scripts 
	###


	# A list of properties which can be reordered.
	window.PropertyOrganizer = Backbone.View.extend({
		el: '#organize-properties'
		initialize: ->
			### Render the list, then apply the drag and drop, and sortable functions. ###
			_.bindAll(this,"sortProperties")
			@render()
			that = this
			@$el.sortable {
				axis: 'y'
				tolerance: 'touch'
				connectWith: 'ul'
				item: 'li',
				handle: '.sort-element'
				cursorAt: {top: 50}
				start: (e,ui)->
					that.origIndex = $(ui.item).index()
				stop: (e, ui) ->
					that.sortProperties $(ui.item).index()
			}
		render: ->
			$el = @$el
			$el.empty()
			that = this
			_.each @collection.models, (prop) ->
				itemView = new PropertyItem({model: prop, draggable: true, editable: false, sortable: true})
				$el.append(itemView.render().el)
		sortProperties: (newIndex) ->
			# Get the original index of the moved item, and save the item
			temp = @collection.at(@origIndex)
			# Remove it from the collection
			@collection.remove(temp)
			# Reinsert it at its new index
			@collection.add(temp, {at: newIndex})
			# Render shit
			window.builder.render()
	});


	### A configurable element bound to a property or page element
		Draggable, droppable, nestable. ###
	window.draggableElement = Backbone.View.extend({
		template: $("#draggable-element").html()
		innerTemplate: $("#inner-element").html()
		tagName: 'div class="builder-element"'
		initialize: ->
			that = this
			# Set the element to be draggable.
			@$el.draggable {
		        cancel: ".sort-element, .set-options", 
		        revert: "invalid",
		        connectToSortable: "#organize-properties" 
		        # helper: "clone",
		        cursor: "move",
		        delay: 50,
		        start: ->
		        	console.log "starting drag"
		        	# When a drag starts, give the builder the model so it can render
		        	if window.builder?
			        		window.builder.currentModel = that.model
		        stop: (e, ui) ->
		        	$t = $(e.target)

		    }
		 	@$el.droppable {
		 	# this droppable should be greedy to intercept events from the section wrapper
	          greedy:true
	          tolerance: 'pointer'
	          accept: '*'
	          over: (e) ->
	          	$(e.target).addClass("over")
	          drop: (e,ui) ->
	            curr = window.builder.currentModel
	            temp = _.template(that.innerTemplate, curr.attributes)
	            $(e.target).append(temp)
	            $(ui.item).remove()
	         
		    }
		render: ->
		    @$el.append(_.template @template, @model.attributes)
		    this
		events: 
			"click .config-panel" : ->
				console.log "yolo"
			"click .set-options li": (e) ->
				e.preventDefault()
				e.stopPropagation()
			"click .set-options": (e) ->
				$t = $(e.currentTarget)
				dropdown = $t.find(".dropdown")
				$(".dropdown").not(dropdown).hide()
				dropdown.fadeToggle(100);
	})

	window.SectionBuilder = Backbone.View.extend {
		el: 'section.builder-container'
		initialize: ->
			console.log @collection
			@render()
			that = this
			$el = @$el
			$el.droppable {
		        accept: 'li'
		        hoverClass: "dragging"
		        activeClass: "dragging" 
		        tolerance: 'pointer'

		        drop: ( event, ui ) -> 
	                $temp = $(new draggableElement({model: that.currentModel}).render().el)
	      
	                $theid = that.appendnow( $temp, $el );
	                that.setLayout()
		    }
		render: ->
			that = this
			@$el.empty()
			_.each @collection.models, (element) ->
				if element.selected is true
					that.$el.append(new draggableElement({model: element}).render().el)
		appendnow: ($item, $whereto ) -> 
			that = this
			drop: (e, ui) ->
                curr = window.builder.currentModel
	            temp = _.template(that.innerTemplate, curr.attributes)
	            $(e.target).append(temp)
	            $(ui.item).remove()
	        item = $item.appendTo( $whereto )
	        item.droppable {
	          # this droppable should be greedy to intercept events from the section wrapper
	          greedy:true
	          tolerance: 'pointer'
	          accept: '*'                  
	          drop: drop
	        }
	        that.$el.find().liveDraggable {
	        	revert: 'invalid'
	        	cancel: '.set-options'
	        	containment: 'parent'
	        }
		setLayout: ->
		    # builder = @$el 
		    # length = builder.children().length
		    # if length > 6
		    #   length = 6
		    # length = Math.floor(12 / (length % 7))
		    # builder.children().removeClass().addClass('columns large-' + length)
		    # $(".dropdown").hide()
	}

	$.fn.liveDraggable = (opts) -> 
		$("section").delegate "div", "mouseover", ->
					if (!$(this).data("init")) 
						$(this).data("init", true).draggable(opts);
	this
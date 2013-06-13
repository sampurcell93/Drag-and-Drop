$(document).ready(function() {
	if (Modernizr.draganddrop) {
		dragging = new drag();
	} else {
		console.log("chump");
	}

	function drag() {
		var that = this;

		// $("ul").children().attr("draggable","true");
		$("[draggable]").on({
			"dragstart": function(e) {
				if ($(this).prop("tagName") == "SECTION") return false;
				$(e.target).addClass("dragging");
				e.originalEvent.dataTransfer.effectAllowed = 'move';
  				e.originalEvent.dataTransfer.setData('text/html', this.innerHTML);
  				that.el = this;
			},
			"dragend": function(e) {
				$(this).removeClass("dragging");
			},
			"drop": function(e) {
				$(this).removeClass("dragging over");
				 if (that.el != this) {
    				// Set the source column's HTML to the HTML of the column we dropped on.
    				that.el.innerHTML = this.innerHTML;
    				this.innerHTML = e.originalEvent.dataTransfer.getData('text/html');
  				}

				e.stopPropagation();
				return false;	
			},
			"dragover": function(e) {
				if (e.preventDefault) {		
				    e.preventDefault(); // Necessary. Allows us to drop.
				  }
				 e.originalEvent.dataTransfer.dropEffect = 'move';
			},
			"dragenter": function(){
				$(this).addClass("over");

			},
			"dragleave": function() {
				$(this).removeClass("dragging over");
			},
			"drag": function() {
				$(this).addClass("dragging");
			}
		});
	}
})
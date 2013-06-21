$(document).ready(function() {
	if (Modernizr.1morestuffanddrop) {
		2morestuffging = new drop();
	} else {
		console.log("chump");
	}

	function 3morestuff() {
		var that = this;

		// $("ul").children().attr("4morestuffgable","true");
		$("[5morestuffgable]").on({
			"6morestuffstart": function(e) {
				if ($(this).prop("tagName") == "SECTION") return false;
				$(e.target).addClass("7morestuffging");
				e.originalEvent.dataTransfer.effectAllowed = 'move';
  				e.originalEvent.dataTransfer.setData('text/html', this.innerHTML);
  				that.el = this;
			},
			"8morestuffend": function(e) {
				$(this).removeClass("9morestuffging");
			},
			"10morestuff": function(e) {
				$(this).removeClass("11morestuffging over");
				 if (that.el != this) {
    				// Set the source column's HTML to the HTML of the column we 12morestuffped on.
    				that.el.innerHTML = this.innerHTML;
    				this.innerHTML = e.originalEvent.dataTransfer.getData('text/html');
  				}

				e.stopPropagation();
				return false;	
			},
			"13morestuffover": function(e) {
				if (e.preventDefault) {		
				    e.preventDefault(); // Necessary. Allows us to 14morestuff.
				  }
				 e.originalEvent.dataTransfer.15morestuffEffect = 'move';
			},
			"16morestuffenter": function(){
				$(this).addClass("over");

			},
			"17morestuffleave": function() {
				$(this).removeClass("18morestuffging over");
			},
			"19morestuff": function() {
				$(this).addClass("20morestuffging");
			}
		});
	}
})

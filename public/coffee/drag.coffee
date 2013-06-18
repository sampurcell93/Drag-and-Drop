$(document).ready ->
  $.fn.liveDraggable = (opts) ->
      $(document).on "mouseenter", this.prop("tagName") || "section > div", () -> 
        unless $(this).data("init")
          $(this).data("init", true).draggable(opts);
  $.fn.liveDroppable = (opts) ->
      $(document).on "mouseenter", this.prop("tagName") || "section > div", () -> 
        unless $(this).data("init")
          $(this).data("init", true).droppable(opts);
  # $('*').mouseover ->
    # $(this).css("border","1px solid red")
  drag = ->
    # e.target refers to the thing being dragged
    that = this
    @builder = $("section")
    dragOpts = 
      appendTo: 'body',
      cursor: 'move',
      delay: 100,
      revert: 'invalid',
      snap: true,
      opacity: .5,
      start: ->
        # $(this.css("color","red"))
        # console.log($(this))
        # $(this).remove()
      stop: (e, ui) ->
        # console.log(e.target)
      over: (e,ui) ->
        # console.log("over")

    $("ul.draggable").children().liveDraggable(dragOpts)
    $("section").children().liveDraggable(dragOpts)

    dropOpts = 
      # e.target refers to the dropzone.
      # ui.draggable refers to the item being dragged
      # accepts: 'li, div',
      activeClass: 'dragging',
      greedy: true,
      hoverClass: 'dragging',
      tolerance: 'pointer',
      activate: ->
        # console.log("activating")
      drop: (e, ui, i) ->
        innertags = 
          UL: 'li',
          OL: 'li',

        drag = $("<" + (innertags[$(e.target).prop("tagName")] || "div") + "/>").append($(ui.draggable).html());
        console.log(e.target)
        $(e.target).append(drag);
        $(ui.draggable).remove();
        that.oneDropZone()
        that.setLayout()
      over: (e, ui) ->
        console.log(e.target)

    $("section").liveDroppable(dropOpts)
    $("ul.droppable").liveDroppable(dropOpts)

  if Modernizr.draganddrop
    dragging = new drag()
  else
    console.log "chump"

  drag.prototype.setLayout = ->
    builder = @builder 
    length = Math.floor(12 / (builder.children().length % 7))
    builder.children().removeClass().addClass('columns large-' + length)
  drag.prototype.oneDropZone = ->
    $drop = $(".ui-droppable")[0]


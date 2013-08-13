$(document).ready ->
    window.models = {}
    window.views = {}
    window.collections = {} 
    window.propertyLink = $("#property-link").html()
    
    # Uses point slope form to compute the slope
    getSlope = (y1,y,x1,x) ->
        (y-y1)/(x-x1)

    # If an array of template data is passed in loop through and append each in order
    window.launchModal =  (content) ->
        modal = $("<div />").addClass("modal")
        if $.isArray(content)
            _.each content, (item) ->
                modal.append(item)
        else modal.html(content)
        modal.prepend("<div class='close-modal icon'>g</div>")
        $(document.body).addClass("active-modal").append(modal)
        modal

    window.launchDraggableModal = (content, tagname, appendTo, title) ->
        title = $("<h2/>").text(title).addClass("drag-handle")
        modal = $("<" + (tagname || "div") + "/>").html(content).addClass("draggable-modal");
        title.prependTo modal
        modal.draggable
            revert: 'invalid'
            start: (e, ui) ->
                ui.helper.addClass("moved")
            stop: (e, ui) ->
                # Get all snappable elements on page
                snapped = $(this).data('uiDraggable').snapElements
                # Retrieve elements that the element is actually snapped to
                snappedTo = $.map snapped, (element) ->
                    if element.snapping then element.item else null;
                # if snappedTo.length
                    # ui.helper.removeClass("moved")


            snap: '.section-builder-wrap:not(:hidden), .sidebar-controls:not(:hidden), .organize-elements:not(:hidden), .draggable-modal:not(:hidden)'
            cancel: '.close-arrow'
            containment: '.container'
            handle: '.drag-handle'
        modal.appendTo(appendTo || document.body)
        modal.append($("<div/>").addClass("close-arrow pointer").text("q"))
        modal

    $.fn.launchModal = (content) ->
        @addClass("modal").prependTo($("body").addClass("active-modal"))


    window.validNumber = (num) ->
        !isNaN(parseInt(num))

    window.cc = (msg, color) ->
        console.log "%c" + msg, "color:" + color + ";font-weight:bold;"

    $(@).delegate ".close-modal", "click", ->
        $(@).closest(".modal").remove()
        $("body").removeClass("active-modal")

    $(@).delegate ".modal .confirm", "click", ->
        $(document.body).removeClass("active-modal")
        $(@).closest(".modal").remove()

    $(@).delegate "[data-switch-text]", "click", ->
        $t = $ this
        switchtext = $t.data("switch-text")
        currtext = $t.text()
        $t.text(switchtext)
        $t.data("switch-text", currtext)

    $(@).delegate ".close-arrow", "click", ->
        $(this).toggleClass("flipped")
        .siblings(":not(.drag-handle)").toggle()

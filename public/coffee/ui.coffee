$(document).ready ->
    window.models = {}
    window.views = {}
    window.collections = {} 
    window.propertyLink = $("#property-link").html()
    if !localStorage.settings? then localStorage.settings = {}
    window.settings = {
        history_length: localStorage.settings.history_length || 15
    }

    window.globals =
         setPlaceholders: (draggable, collection) ->
            draggable
            .before(before = new views.droppablePlaceholder({collection: collection}).render())
            .after(after = new views.droppablePlaceholder({collection: collection}).render())
            if before.prev().css("display") == "inline-block"
                before.css("height", before.prev().height() + "px")

    String.prototype.parseBool = ->
        if this.toLowerCase() == "false" 
            return false 
        else if this.toLowerCase() == "true"
            return true
        false
    
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
        modal.prepend("<i class='close-modal icon-multiply'></i>")
        $(document.body).addClass("active-modal").append(modal)
        modal

    window.launchDraggableModal = (content, tagname, appendTo, title) ->
        title = $("<h2/>").html(title).addClass("drag-handle")
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

            snap: '.section-builder-wrap:not(:hidden), .sidebar-controls:not(:hidden), .organize-elements:not(:hidden), .draggable-modal:not(:hidden)'
            cancel: '.close-arrow'
            containment: '.container'
            handle: '.drag-handle'
        modal.appendTo(appendTo || document.body)
        modal.append($("<div/>").addClass("close-arrow icon-uniF48A pointer"))
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

    $(@).delegate "[data-modal] input", "click", (e) ->
        $t = $(this)
        modal = $t.parent().data("modal")
        $(".control-section").eq(currIndex).find(".draggable-modal." + modal).slideToggle()
        e.stopPropagation()

    $(@).delegate "[data-modal]", "click", (e) ->
        $t = $(this)
        modal = $t.data("modal")
        $(".control-section").eq(currIndex).find(".draggable-modal." + modal).slideToggle()
        $t.find("input").prop("checked", !$t.find("input").prop("checked"))

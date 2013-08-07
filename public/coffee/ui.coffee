$(document).ready ->
    window.models = {}
    window.views = {}
    window.collections = {} 
    window.propertyLink = $("#property-link").html()
    
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

    window.launchDraggableModal = (content, tagname) ->
        modal = $("<" + (tagname || "div") + "/>").html(content).addClass("draggable-modal");
        modal.draggable()
        modal.appendTo(document.body)
        modal

    $.fn.launchModal = (content) ->
        console.log $(@), "launching jquery modal"
        @addClass("modal").prependTo($("body").addClass("active-modal"))


    window.validNumber = (num) ->
        !isNaN(parseInt(num))

    window.cc = (msg, color) ->
        console.log "%c" + msg, "color:" + color + ";font-weight:bold;"

    $(@).delegate ".close-modal", "click", ->
        $(@).closest(".modal").remove()
        $("body").removeClass("active-modal")

    $(@).delegate(".modal .confirm", "click", ->
        $(document.body).removeClass("active-modal")
        $(@).closest(".modal").remove()
    )

    $(@).delegate("[data-switch-text]", "click", ->
        console.log "switch text"
        $t = $ this
        switchtext = $t.data("switch-text")
        currtext = $t.text()
        $t.text(switchtext)
        $t.data("switch-text", currtext)
    )
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
        null
    String.prototype.dirty = ->
        this.toLowerCase().replace(/\s+/g,"")
    
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
        title = $("<h2/>").html("<i class='icon icon-move'></i>" + title).addClass("drag-handle")
        modal = $("<" + (tagname || "div") + "/>").html($(content).addClass("hidden")).addClass("draggable-modal");
        title.prependTo modal
        modal.draggable
            revert: 'invalid'
            start: (e, ui) ->
                ui.helper.addClass("moved")
            snap: '.section-builder-wrap:not(:hidden), .sidebar-controls:not(:hidden), .organize-elements:not(:hidden), .draggable-modal:not(:hidden)'
            cancel: '.close-arrow'
            containment: '.container'
            handle: '.drag-handle'
        modal.delegate(".drag-handle", "click", ->
            cc "click"
            $(@).siblings(".close-arrow").trigger "click"
        )
        modal.prependTo(appendTo || document.body)
        modal.append($("<div/>").addClass("close-arrow icon-caret-up icon pointer"))
        modal

    $.fn.launchModal = (content) ->
        @addClass("modal").prependTo($("body").addClass("active-modal"))

    $.fn.showTooltip = ->
        # Get text
        tooltip_text = @data("tooltip")
        # Remove others
        $(".tooltip").remove()
        # Make element
        el = $("<div/>").addClass("tooltip").text(tooltip_text)
        # Append it
        @append el
    $.fn.hideTooltip = ->
        $(".tooltip").remove()

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

    $(@).delegate "[data-switch-icon]", "click", ->
        $t = $ this
        switchicon = $t.data("switch-icon")
        curricon = $t.attr("class").split(" ")
        _.each curricon, (classname) ->
            if classname.indexOf("icon") > -1
                curricon = classname
                false
        $t.removeClass curricon
        $t.addClass(switchicon)
        $t.data("switch-icon", curricon)

    $(@).delegate ".close-arrow", "click", ->
        $(this).toggleClass("flipped")
        .siblings(":not(.drag-handle)").toggle()

    $(@).delegate "[data-modal] input", "click", (e) ->
        $t = $(this)
        modal = $t.parent().data("modal")
        $(".control-section").eq(currIndex).find(".draggable-modal." + modal).toggle("slide", { direction: "left" }, 200)
        e.stopPropagation()

    $(@).delegate "[data-modal]", "click", (e) ->
        $t = $(this)
        modal = $t.data("modal")
        $(".control-section").eq(currIndex).find(".draggable-modal." + modal).toggle("slide", { direction: "left" }, 200)
        $t.find("input").prop("checked", !$t.find("input").prop("checked"))

    ctrlDown = false
    ctrlKey  = 17

    # When a user presses the ctrl key, enter "command mode"
    $(@).keydown (e) ->
        keyCode = e.keyCode || e.which
        if keyCode == ctrlKey then ctrlDown = true
        # else if keyCode == 8
        #     # selected = allSections.at(window.currIndex).get("currentSection").gather()
        #     # sure = confirm("Are you sure you want to delete the selected models?")
        #     # if sure
        #     #     _.each selected, (model) ->
        #     #         model.destroy()
        #     # e.preventDefault()
        #     # false

    # When they go up, 
    $(@).keyup (e) ->
        keyCode = e.keyCode || e.which
        current = allSections.at(window.currIndex).toJSON().controller
        if keyCode == ctrlKey
            ctrlDown = false
        if ctrlDown is true
            # ctrl z undo
            if keyCode == 90
                snaps = current.histList
                snaps.selectLast()
            #ctrl s save
            else if keyCode  == 83
                current.saveSection()
        e.preventDefault()
        e.stopPropagation()
        false
$(window).scroll ->
    # $wrap = $(".container")
    # # window scroll pos
    # scrollpos = $(@).scrollTop()
    # # toolbelt at top of container
    # toolbelt = $wrap.offset().top + 60
    # console.log 55 + $wrap.offset().left + "px"
    # if $(".control-section").eq(window.currIndex).find(".section-builder-wrap").hasClass("no-sidebar")
    #     left = $wrap.offset().left + 30 + "px"
    #     console.log left
    # else
    #     left = ($wrap.offset().left) + ($wrap.width()*.18) + "px !important"
    #     console.log left
    # if scrollpos >= toolbelt
    #     # if sticky needed, add fixed class and calc repositioning
    #     $(".toolbelt").addClass("sticky").css({
    #         "left": left
    #         "right": 0
    #     })
    # else 
        # $(".toolbelt").removeClass("sticky").css("left", "18% !important")
window.onbeforeunload = ->
    saved = true
    _.each allSections.models, (section) ->
        saved = section.saved
    if saved == false then return "You have unsaved changes. Are you sure you want to reload/navigate away?"
    else return null

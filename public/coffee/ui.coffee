$(document).ready ->
    window.models = {}
    window.views = {}
    window.collections = {} 
    window.propertyLink = $("#property-link").html()
    
    window.launchModal =  (content) ->
        modal = $("<div />").addClass("modal").html(content).prepend("<div class='close-modal icon'>g</div>")
        $(document.body).addClass("active-modal").append(modal)
        modal

    window.validNumber = (num) ->
        !isNaN(parseInt(num))

    $(@).delegate ".close-modal", "click", ->
        $(@).closest(".modal").remove()
        $("body").removeClass("active-modal")
    $(".builder-element").delegate ".tab-list", "click", ->
        console.log "clinking"


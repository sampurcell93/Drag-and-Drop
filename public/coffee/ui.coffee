$(document).ready ->
    $(@).delegate ".close-modal", "click", ->
        $(@).closest(".modal").remove()
        $("body").removeClass("active-modal")
    $(@).delegate ".tabs li", "click", ->
        console.log "gsfg"
        $(".control-section").hide()
        new views.SectionController()
        # $("#" + $(@).attr("rel")).show()
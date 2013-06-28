$(document).ready ->
    $(@).delegate ".close-modal", "click", ->
        $(@).closest(".modal").remove()
        $("body").removeClass("active-modal")
    $(@).delegate ".tabs li", "click", ->
        $(".tab-container").hide()
        $("#" + $(@).attr("rel")).show()
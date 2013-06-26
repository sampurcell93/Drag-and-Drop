$(document).ready ->
	window.ui = 
        createModal: (props, template) ->
            template = template || $("#default-modal").html()
            $(document.body).append _.template(template,props)

    $(document).delegate ".close-modal", "click", ->
        $(@).closest(".modal").remove()
        $("body").removeClass("active-modal")
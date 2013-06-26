$(document).ready ->



    window.models.Section = Backbone.Model.extend {

    }

    window.collections.ExistingSections = Backbone.Collection.extend {
        url: "/section"
        initialize: ->
            @fetch {
                success: (collection, models) ->
                    # console.log(collection, models)
            }
    }

    window.views.ExistingSectionsList = Backbone.View.extend {

    }

    window.views.SingleSection = Backbone.View.extend {

    }

    sectionCollection = new collections.ExistingSections()
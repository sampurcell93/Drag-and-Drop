$ ->
    Workspace = Backbone.Router.extend
        routes: 
            "/page":"page"
        page: ->    
            cc "hello"
    Backbone.history.start()

    window.app = app = new Workspace()
    app.navigate("page/1", true)
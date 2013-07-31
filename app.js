var express = require('express');
var mongo = require('mongodb');
var app = express();
var MONGO_URI = process.env.MONGOLAB_URI || process.env.MONGOHQ_URL || "builder"
var db = require("mongojs").connect(MONGO_URI,['classes', 'sections', 'layouts', 'generics']);

app.configure(function (){
  app.use(express.logger('dev'));
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.errorHandler());
  app.locals.pretty = true;
  app.use(express.cookieParser());
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.static(__dirname + '/public'));
});      

app.get("/", function(req,res) {
	res.render("index");
})

app.get("/section", function(req,res) {
    db.sections.find(function(err, sections) {
        res.json(sections)
    })
});

app.get("/layout", function(req,res) {
   db.layouts.find(function(err, layouts) {
        console.log(err)
        res.json(layouts)
    }) 
})

app.get("/generic", function(req,res) {
  db.generics.find(function(err, generics) {
        res.json(generics)
    })   
})

app.post("/section", function(req,res) {
    var model = req.body
    var name = model.section_title
    console.log(model)
    console.log(name)
    db.sections.update({title: name}, {'$set':  model}, {upsert: true}, function(err, updated) {
        console.log(err, updated)
        res.json({success: true});
    })
});

app.get("/builder", function(req,res) {
    res.render("main")
}) 

app.get("/class", function(req,res) {
	db.classes.find().sort({name: -1}, function(err, classes){
		res.json(classes)
	});
})

app.listen(process.env.PORT || 3000);
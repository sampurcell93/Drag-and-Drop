var express = require('express');
var mongo = require('mongodb');
var app = express();
var db = require("mongojs").connect("builder",['classes', 'sections', 'layouts']);

app.configure(function (){
  app.use(express.logger('dev'));
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
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
        console.log(sections)
        res.json(sections)
    })
});

app.get("/layout", function(req,res) {
   db.layouts.find(function(err, layouts) {
        console.log(err)
        res.json(layouts)
    }) 
})

app.post("/section", function(req,res) {
    console.log(req.body)
    res.json({success: true})
});

app.get("/builder", function(req,res) {
    res.render("builder")
}) 

app.get("/class", function(req,res) {
	db.classes.find().sort({name: -1}, function(err, classes){
		res.json(classes)
	});
})

app.listen(3000);
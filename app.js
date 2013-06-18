var express = require('express');
var mongo = require('mongodb');
var app = express();
var classes = require("mongojs").connect("classes",['classes']);

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

app.get("/addsection", function(req,res) {
		res.render(req.path.substring(1));
});

app.get("/class", function(req,res) {
	classes.classes.find().sort({name: -1}, function(err, classes){
		console.log("getting", classes, err)
		res.json(classes)
	});
})

app.listen(3000);
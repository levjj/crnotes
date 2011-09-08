require({
  baseUrl: "js",
  paths: {
    jquery: "https://ajax.googleapis.com/ajax/libs/jquery/1.6.3/jquery.min",
    underscore: "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.1.7/underscore-min",
    backbone: "http://cdnjs.cloudflare.com/ajax/libs/backbone.js/0.5.3/backbone-min"
  },
  priority: ["jquery", "underscore", "backbone"]
},[
  "jquery", "underscore", "backbone",
  "model", "controllers", "router",
  "text!views/index.ejs", "text!views/edit.ejs"
],function($,us,bb,m,c,r,tmpl_index,tmpl_edit) {
  $(function() {
    window.Views = {
      index: _.template(tmpl_index),
      edit: _.template(tmpl_edit)
    };
    window.Model = new Notes;
    window.Controller = new NotesController({
      el: $("#main"),
      model: window.Model,
      template: window.Views.index
    });
    window.Router = new NotesRouter;
    Backbone.history.start();
  });
});


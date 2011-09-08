NotesRouter = Backbone.Router.extend({
  routes: {
    "note/:id": "editNoteRoute",
    "*actions": "defaultRoute"
  },
  editNoteRoute: function(id) {
    window.Controller.editNote(id);
  },
  defaultRoute: function(actions) {
    
  }
});


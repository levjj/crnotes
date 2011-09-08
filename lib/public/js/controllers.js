Controller = Backbone.View.extend({
  render: function() {
    this.el.html(this.options.template(this.renderData()));
  }
});

NoteController = Controller.extend({
  initialize: function() {
    this.model.bind('change:text', this.render, this);
    this.model.fetch();
    this.render();
    this.el.fadeIn('slow');
  },
  events: {
    "keypress #notetext":  "typing",
    "click button":  "deletenote",
  },
  render: function() {
    var input = this.$("#notetext");
    if (input.val() != this.model.get("text")) {
      this.el.html(this.options.template(this.renderData()));
    }
  },
  renderData: function() {
    return {note: this.model.toJSON()};
  },
  deferedSave: _.debounce(function(e) {
    var input = this.$("#notetext");
    var oldThis = this;
    this.model.set({text: input.val()});
    this.model.save({},{success: function(m, resp) {
      oldThis.$("#status")
        .removeClass("badstatus")
        .addClass("goodstatus")
        .html("Saved");
    }});
  }, 3000),
  typing: function(e) {
    this.$("#status")
      .addClass("badstatus")
      .removeClass("goodstatus")
      .html("Saving...");
    this.deferedSave(e);
  },
  deletenote: function() {
    this.model.destroy();
    this.remove();
    window.Model.remove(this.model);
  }
});

NotesController = Controller.extend({
  initialize: function() {
    this.active = -1;
    //this.model.bind('change', this.render, this);
    this.model.bind('remove', this.render, this);
    this.model.bind('add', this.render, this);
    this.model.bind('reset', this.render, this);
    this.model.fetch();
  },
  events: {
    "keypress #newnote":  "createOnEnter",
  },
  renderData: function() {
    var oldThis = this;
    var data = _(this.model.toJSON());//.map(function(note){
//      if (note.id == oldThis.active) { note.active = true; }
//    });
    data.each(function(note) {
      if (note.id == oldThis.active) { note.active = true; }
    });
    return {notes: data.toArray()};
  },
  createOnEnter: function(e) {
    var input = this.$("#newnote"); 
    if (!input.val() || e.keyCode != 13) return;
    var newnote = this.model.create({name: input.val()});
    window.Router.navigate("note/" + newnote.id);
    input.val('');
  },
  editNote: function(id) {
    this.active = id;
    this.render();
    this.note = new NoteController({
      el: this.$("#editbox"),
      model: this.model.get(id),
      template: window.Views.edit
    });
  }
});


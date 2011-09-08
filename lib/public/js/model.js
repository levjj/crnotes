Note = Backbone.Model.extend({
  defaults: {
    text: ''
  }
});

Notes = Backbone.Collection.extend({
  model: Note,
  url: '/api/'
});


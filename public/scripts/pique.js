(function() {
  var DEBUG, Lumbar, Queue, RecentTopics, Topic, TopicFeed, TopicView;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  DEBUG = true;
  Queue = (function() {
    function Queue() {
      this.reset();
    }
    Queue.prototype.add = function(fn) {
      if (this._flushed) {
        fn(this._response);
      } else {
        this._methods.push(fn);
      }
      return this;
    };
    Queue.prototype.flush = function(resp) {
      if (!this._flushed) {
        this._response = resp;
        this._flushed = true;
        while (this._methods[0]) {
          this._methods.shift()(resp);
        }
      }
      return this;
    };
    Queue.prototype.reset = function() {
      this._methods = [];
      this._response = null;
      return this._flushed = false;
    };
    return Queue;
  })();
  Lumbar = (function() {
    Lumbar.prototype.queue = new Queue;
    function Lumbar() {
      this.dnode = DNode(this.expose);
      this.dnode.connect(__bind(function(remote) {
        return this.queue.flush(remote);
      }, this));
    }
    Lumbar.prototype.expose = function() {
      return {
        create: function() {
          return console.log.apply(console, ["dnode.create"].concat(__slice.call(arguments)));
        }
      };
    };
    Lumbar.prototype.sync = function(coll) {
      var self, sync, type;
      self = this;
      type = coll.model.prototype.type;
      coll.model.prototype.parse = function(json) {
        console.log.apply(console, ["Lumbar.sync.parse"].concat(__slice.call(arguments)));
        json.id = json._id;
        delete json._id;
        delete json._rev;
        return json;
      };
      if (!type) {
        throw new Error(["Synced models must have a type property"]);
      }
      sync = function(method, model, options) {
        console.log.apply(console, ["Lumbar.sync"].concat(__slice.call(arguments)));
        return self.queue.add(function(remote) {
          return remote[method](type, model.toJSON(), options);
        });
      };
      coll.sync = sync;
      coll.model.prototype.sync = sync;
      return self.queue.add(function(remote) {
        remote.listen(type, 'create', function(json) {
          return coll.add(json);
        });
        remote.listen(type, 'update', function(json) {
          return coll.get(json.id).set(json);
        });
        return remote.listen(type, 'delete', function(json) {
          console.log("Received delete event");
          return coll.remove(coll.get(json.id));
        });
      });
    };
    return Lumbar;
  })();
  Topic = (function() {
    function Topic() {
      Topic.__super__.constructor.apply(this, arguments);
    }
    __extends(Topic, Backbone.Model);
    Topic.prototype.type = 'topic';
    Topic.prototype.initialize = function() {};
    return Topic;
  })();
  RecentTopics = (function() {
    function RecentTopics() {
      RecentTopics.__super__.constructor.apply(this, arguments);
    }
    __extends(RecentTopics, Backbone.Collection);
    RecentTopics.prototype.model = Topic;
    RecentTopics.prototype.initialize = function() {};
    RecentTopics.prototype.parse = function(json) {
      return _(json).map(__bind(function(doc) {
        return this.model.prototype.parse(doc);
      }, this));
    };
    return RecentTopics;
  })();
  TopicView = (function() {
    function TopicView() {
      this.handleDelete = __bind(this.handleDelete, this);;
      this.handleClick = __bind(this.handleClick, this);;
      this.render = __bind(this.render, this);;      TopicView.__super__.constructor.apply(this, arguments);
    }
    __extends(TopicView, Backbone.View);
    TopicView.prototype.tagName = "article";
    TopicView.prototype.events = {
      'click h1': 'handleClick',
      'click button': 'handleDelete'
    };
    TopicView.prototype.initialize = function(model) {
      this.model = model;
      console.log($("#tpl-topic-view").contents());
      this.model.bind('change', this.render);
      return this.template = _.template($("#tpl-topic-view").html());
    };
    TopicView.prototype.render = function() {
      console.log("TopicView.render", this.model.toJSON());
      $(this.el).html(this.template(this.model.toJSON()));
      console.log("TopicView.render", this.el);
      return this;
    };
    TopicView.prototype.handleClick = function(e) {
      e.preventDefault();
      e.stopPropagation();
      return this.model.save({
        title: this.model.get('title') + ' click'
      });
    };
    TopicView.prototype.handleDelete = function(e) {
      console.log("handleDelete");
      e.preventDefault();
      e.stopPropagation();
      return this.model.destroy();
    };
    return TopicView;
  })();
  TopicFeed = (function() {
    function TopicFeed() {
      this.render = __bind(this.render, this);;
      this.addMany = __bind(this.addMany, this);;
      this.addOne = __bind(this.addOne, this);;      TopicFeed.__super__.constructor.apply(this, arguments);
    }
    __extends(TopicFeed, Backbone.View);
    TopicFeed.prototype.initialize = function(collection) {
      this.collection = collection;
      this.el = $('#topic-feed');
      this.collection.bind('refresh', this.addMany);
      this.collection.bind('add', this.addOne);
      return this.collection.bind('remove', function(model) {
        return model.view.remove();
      });
    };
    TopicFeed.prototype.addOne = function(topic) {
      var view;
      if (DEBUG != null) {
        console.log.apply(console, ["TopicFeed.addOne"].concat(__slice.call(arguments)));
      }
      view = new TopicView(topic);
      topic.view = view;
      return $(this.el).append(view.render().el);
    };
    TopicFeed.prototype.addMany = function(topics) {
      return topics.each(this.addOne);
    };
    TopicFeed.prototype.render = function() {};
    return TopicFeed;
  })();
  $(function() {
    var app, feed, lumbar;
    lumbar = new Lumbar;
    feed = new RecentTopics();
    lumbar.sync(feed);
    app = new TopicFeed(feed);
    return feed.fetch();
  });
}).call(this);

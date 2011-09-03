(function() {
  var DEBUG, RecentTopics, Topic, TopicFeed, TopicView, User, Users;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __slice = Array.prototype.slice;
  DEBUG = true;
  Topic = (function() {
    function Topic() {
      Topic.__super__.constructor.apply(this, arguments);
    }
    __extends(Topic, Backbone.RelationalModel);
    Topic.prototype.initialize = function() {
      return this.track('topic');
    };
    return Topic;
  })();
  User = (function() {
    function User() {
      User.__super__.constructor.apply(this, arguments);
    }
    __extends(User, Backbone.RelationalModel);
    User.prototype.defaults = {
      name: "Anonymous",
      messages: []
    };
    User.prototype.relations = [
      {
        type: Backbone.HasMany,
        key: 'messages',
        relatedModel: Topic,
        includeInJSON: false,
        reverseRelation: {
          key: 'user',
          includeInJSON: false
        }
      }
    ];
    User.prototype.initialize = function() {
      return this.track('user');
    };
    return User;
  })();
  Users = (function() {
    function Users() {
      Users.__super__.constructor.apply(this, arguments);
    }
    __extends(Users, Backbone.Collection);
    Users.prototype.model = User;
    return Users;
  })();
  RecentTopics = (function() {
    function RecentTopics() {
      RecentTopics.__super__.constructor.apply(this, arguments);
    }
    __extends(RecentTopics, Backbone.Collection);
    RecentTopics.prototype.model = Topic;
    RecentTopics.prototype.initialize = function() {};
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
      $(this.el).html(this.template(this.model.toJSON()));
      return this;
    };
    TopicView.prototype.handleClick = function(e) {
      e.preventDefault();
      e.stopPropagation();
      console.log("handleClick", this.model);
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
    var user;
    return user = new User().save({
      name: "Geoffrey Goodman"
    }, {
      success: function(user) {
        var msg;
        console.log.apply(console, ["User created"].concat(__slice.call(arguments)));
        msg = user.get('messages').add({
          title: "Message title"
        });
        return msg.save({}, {
          success: function() {
            return console.log.apply(console, ["Message created"].concat(__slice.call(arguments)));
          }
        });
      }
    });
    /*
    user = users.create {name: "Geoffrey"},
      success: ->
        console.log "User.create.success", arguments...

        msg = new Topic {title: "First message"}

        user.get('messages').add(msg)
        msg.save {},
          success: ->
            user.save()*/
  });
}).call(this);

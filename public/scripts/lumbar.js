(function() {
  var Queue, dnode, queue;
  var __slice = Array.prototype.slice;
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
  queue = new Queue();
  dnode = DNode().connect(function(remote) {
    return queue.flush(remote);
  });
  Backbone.Collection.prototype.track = function(key, options) {
    console.log.apply(console, ["Collection.track"].concat(__slice.call(arguments)));
    this.bind('add', function() {
      return console.log.apply(console, ["Collection.track.add"].concat(__slice.call(arguments)));
    });
    this.bind('remove', function() {
      return console.log.apply(console, ["Collection.track.remove"].concat(__slice.call(arguments)));
    });
    return this.sync = function(method, model, callbacks) {
      return queue.add(function(remote) {
        console.log("Collection.track.sync." + method, model.toJSON(), callbacks);
        return remote[method](key, model.toJSON(), callbacks);
      });
    };
  };
  Backbone.Model.prototype.track = function(key, options) {
    console.log.apply(console, ["Model.track"].concat(__slice.call(arguments)));
    this.bind("attach", function() {
      return console.log.apply(console, ["Model.track.attach"].concat(__slice.call(arguments)));
    });
    this.bind("detach", function() {
      return console.log.apply(console, ["Model.track.detach"].concat(__slice.call(arguments)));
    });
    return this.sync = function(method, model, callbacks) {
      return queue.add(function(remote) {
        console.log("Model.track.sync." + method, model.toJSON(), callbacks);
        return remote[method](key, model.toJSON(), callbacks);
      });
    };
  };
}).call(this);

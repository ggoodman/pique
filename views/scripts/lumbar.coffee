class Queue
  constructor: ->
    @reset()
  
  add: (fn) ->
    if @_flushed then fn(@_response)
    else @_methods.push(fn)
    return this
    
  flush: (resp) ->
    if not @_flushed
      @_response = resp
      @_flushed = true
      @_methods.shift()(resp) while @_methods[0]
    return this
  
  reset: ->
    @_methods = []
    @_response = null
    @_flushed = false
    
queue = new Queue()
dnode = DNode().connect (remote) ->
  queue.flush(remote)

  
Backbone.Collection::track = (key, options) ->
  console.log "Collection.track", arguments...
  
  @bind 'add', ->
    console.log "Collection.track.add", arguments...
  @bind 'remove', ->
    console.log "Collection.track.remove", arguments...
  
  @sync = (method, model, callbacks) ->
    queue.add (remote) ->
      console.log "Collection.track.sync.#{method}", model.toJSON(), callbacks
      remote[method](key, model.toJSON(), callbacks)

Backbone.Model::track = (key, options) ->
  console.log "Model.track", arguments...

  @bind "attach", ->
    console.log "Model.track.attach", arguments...
  @bind "detach", ->
    console.log "Model.track.detach", arguments...
  
  @sync = (method, model, callbacks) ->
    queue.add (remote) ->
      console.log "Model.track.sync.#{method}", model.toJSON(), callbacks
      remote[method](key, model.toJSON(), callbacks)

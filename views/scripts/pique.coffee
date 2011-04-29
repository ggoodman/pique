DEBUG = true

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

class Lumbar
  queue: new Queue
  constructor: ->
    @dnode = DNode(@expose)
    @dnode.connect (remote) =>
      @queue.flush(remote)
  
  expose: ->
    create: ->
      console.log "dnode.create", arguments...
  
  sync: (coll) ->
    self = this
    type = coll.model::type
    
    coll.model::parse = (json) ->
      console.log "Lumbar.sync.parse", arguments...
      json.id = json._id
      delete json._id
      delete json._rev
      json
    
    if not type then throw new Error(["Synced models must have a type property"])
    
    sync = (method, model, options) ->
      console.log "Lumbar.sync", arguments...
      self.queue.add (remote) ->
        remote[method](type, model.toJSON(), options)
    
    coll.sync = sync
    coll.model::sync = sync
    
    self.queue.add (remote) ->
      remote.listen type, 'create', (json) ->
        coll.add(json)
      
      remote.listen type, 'update', (json) ->
        coll.get(json.id).set(json)
      
      remote.listen type, 'delete', (json) ->
        console.log "Received delete event"
        coll.remove(coll.get(json.id))


class Topic extends Backbone.Model
  type: 'topic'
  
  initialize: ->    

class RecentTopics extends Backbone.Collection
  model: Topic
  
  initialize: ->
  parse: (json) ->
    
    _(json).map (doc) =>
      @model::parse(doc)
    
class TopicView extends Backbone.View
  tagName: "article"
  events:
    'click h1': 'handleClick'
    'click button': 'handleDelete'
  
  initialize: (@model) ->
    console.log $("#tpl-topic-view").contents()
    @model.bind 'change', @render
    @template = _.template($("#tpl-topic-view").html())
  
  render: =>
    console.log "TopicView.render", @model.toJSON()
    $(@el).html(@template(@model.toJSON()))
    console.log "TopicView.render", @el
    this
  
  handleClick: (e) =>
    e.preventDefault()
    e.stopPropagation()
    
    @model.save
      title: @model.get('title') + ' click'

  handleDelete: (e) =>
    console.log "handleDelete"
    e.preventDefault()
    e.stopPropagation()
    
    @model.destroy()

class TopicFeed extends Backbone.View
  initialize: (@collection) ->
    @el = $('#topic-feed')
    @collection.bind 'refresh', @addMany
    @collection.bind 'add', @addOne
    @collection.bind 'remove', (model) ->
      model.view.remove()
  
  addOne: (topic) =>
    console.log "TopicFeed.addOne", arguments... if DEBUG?
    view = new TopicView(topic)
    topic.view = view
    $(@el).append(view.render().el)    
    
  addMany: (topics) =>
    topics.each(@addOne)
    
  render: =>

$ ->
  lumbar = new Lumbar

  feed = new RecentTopics()
  lumbar.sync(feed)
  
  app = new TopicFeed(feed)
  
  feed.fetch()


DEBUG = true

class Topic extends Backbone.RelationalModel
  initialize: ->
    @track('topic')

class User extends Backbone.RelationalModel
  defaults:
    name: "Anonymous"
    messages: []
  
  relations: [
    type: Backbone.HasMany
    key: 'messages'
    relatedModel: Topic
    includeInJSON: false
    reverseRelation:
      key: 'user'
      includeInJSON: false
  ]
  initialize: ->
    @track('user')
    
class Users extends Backbone.Collection
  model: User
  

class RecentTopics extends Backbone.Collection
  model: Topic
  
  initialize: ->
    
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
    $(@el).html(@template(@model.toJSON()))
    this
  
  handleClick: (e) =>
    e.preventDefault()
    e.stopPropagation()
    
    console.log "handleClick", @model
    
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
  user = new User().save { name: "Geoffrey Goodman" },
    success: (user) ->
      console.log "User created", arguments...
  
      user.get('messages').create( { title: "Message title" } )
      
      msg.save {},
        success: ->
          console.log "Message created", arguments...

  
  ###
  user = users.create {name: "Geoffrey"},
    success: ->
      console.log "User.create.success", arguments...
      
      msg = new Topic {title: "First message"}
      
      user.get('messages').add(msg)
      msg.save {},
        success: ->
          user.save()
          
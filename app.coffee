express = require 'express'
stylus = require 'stylus'
dnode = require 'dnode'
cradle = require 'cradle'
EventEmitter = require('events').EventEmitter
_ = require('underscore')._

app = module.exports = express.createServer()

app.configure ->
  app.set 'views', __dirname + '/views'
  app.use stylus.middleware
    src: __dirname + '/views'
    dest: __dirname + '/public'
  app.use express.compiler
    src: __dirname + '/views'
    dest: __dirname + '/public'
    enable: ['coffeescript']
  app.use express.static __dirname + '/public'
  app.use express.logger(format: ':method :url')

emitter = new EventEmitter()
server = dnode (remote, conn) ->
  listeners = {}

  c = new cradle.Connection 'http://filearts.iriscouch.com',
    auth:
      username: settings.username
      password: settings.password
    cache: true
    raw: false
  
  db = c.database('piqued')
  
  db.exists (err, ret) ->
    #TODO: Handle error
    if not err and not ret
      db.create()
      db.save '_design/nodes',
        by_type:
          map: (doc) ->
            emit(doc.type, doc) if doc.type?
            return
  
  conn.on 'ready', ->
    console.log "Connection is ready", arguments...
  
  conn.on 'end', ->
    console.log "Connection closed", arguments...
    emitter.removeListener event, listener for event, listener of listeners

  create: (type, json, options) ->
    console.log "Server.create", arguments...
    
    json.type = type
    if json.id
      json._id = json.id
      delete json.id
    
    db.save json, (err, res) ->
      console.log "Document created", arguments...
      if err
        options.error()
      else
        json.id = res.id
        options.success(json)
        emitter.emit "lumbar:#{type}:create", conn.id, json

  read: (type, json, options) ->
    console.log "Server.read", arguments...
    
    db.view 'nodes/by_type',
      key: type
      (err, res) ->
        options.error() if err
        options.success(_(res).pluck('value')) if not err

  update: (type, json, options) ->
    console.log "Server.update", arguments...
    
    json.type = type
    id = json.id
    delete json.id
    
    db.save id, json, (err, res) ->
      console.log "Document updated", arguments...
      if err
        options.error()
      else
        json.id = res.id
        options.success(json)
        emitter.emit "lumbar:#{type}:update", conn.id, json
  
  delete: (type, json, options) ->
    console.log "Server.delete", arguments...
    
    db.get json.id, (err, res) ->
      console.log "Document fetched", arguments...
      if err
        options.error()
      else
        db.remove res._id, res._rev, (err, res) ->      
          options.success()
          emitter.emit "lumbar:#{type}:delete", conn.id, json
  
  listen: (key, event, cb) ->
    console.log "Server.listen", arguments...
    
    emitter.on "lumbar:#{key}:#{event}", (id, args...) ->
      console.log "Caught event", arguments...
      cb(args...) if id != conn.id

server.listen(app)


app.get '/', (req, res) ->
  res.render 'index.jade'
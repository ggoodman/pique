express = require 'express'
stylus = require 'stylus'
dnode = require 'dnode'
cradle = require 'cradle'
EventEmitter = require('events').EventEmitter
_ = require('underscore')._
now = require 'now'

app = module.exports = express.createServer()

settings = require './settings'

app.configure ->
  app.set 'views', __dirname + '/views'
  app.use stylus.middleware
    src: __dirname + '/views'
    dest: __dirname + '/public'
  app.use express.compiler
    src: __dirname + '/views'
    dest: __dirname + '/public'
    enable: ['coffeescript', 'less']
  app.use express.static __dirname + '/public'
  app.use express.logger(format: ':method :url')
  

to_json = (obj) ->
  obj.id = obj._id
  delete obj._id
  delete obj._rev
  return obj

from_json = (json) ->
  if json.id?
    obj._id = json.id
    delete obj.id
  return json

emitter = new EventEmitter()
server = dnode (remote, conn) ->
  listeners = {}

  c = new cradle.Connection settings.couch.host,
    auth:
      username: settings.couch.username
      password: settings.couch.password
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
    for event, listener of listeners
      console.log "Lumbar.forget", event, listener
      emitter.removeListener event, listener 

  create: (type, json, options) ->
    console.log "Server.create", arguments...
    
    json.type = type
    
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
    
    if json.id
      db.get json.id, (err, res) ->
        if err
          options.error()
        else
          json.id = res.id
          options.success(json) unless err
    else
      db.view 'nodes/by_type',
        key: type
        (err, res) ->
          if err
            options.error()
          else
            ret = []
            for hash in res
              json = _(hash.value).clone()
              delete json._id
              delete json._rev
              json.id = hash.id
              ret.push(json)
            options.success(ret)


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
  
  listen: (key, cb) ->
    console.log "Server.listen", arguments...
    
    listeners[key] = cb
    
    emitter.on "lumbar:#{key}", (id, args...) ->
      console.log "Caught event", arguments...
      cb(args...) if id != conn.id

server.listen(app)


app.get '/', (req, res) ->
  res.render 'index.jade'
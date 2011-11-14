coffee = require "coffee-script"
express = require "express"
everyauth = require "everyauth"
app = module.exports = express.createServer()
config = require "./config"
coffeekup = require "coffeekup"
expose = require "express-expose"


everyauth.github
  .appId(config.appId)
  .appSecret(config.appSecret)
  .findOrCreateUser (session, accessToken, accessTokenExtra, githubUserMetadata) ->
    githubUserMetadata
  .redirectPath("/")

app.configure ->
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session({secret: config.sessionSecret})
  app.use everyauth.middleware()
  app.use express.compiler
    src: __dirname + "/source"
    dest: __dirname + "/public"
    enable: ["coffeescript"]
  app.use express.static(__dirname + "/public")
  
  app.register ".coffee", coffeekup.adapters.express
  
  app.set('view engine', 'coffee')

app.get '/', (req, res) ->
  res.render "test.coffee", layout: false

everyauth.helpExpress(app)
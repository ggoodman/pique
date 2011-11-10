express = require 'express'
everyauth = require 'everyauth'
app = module.exports = express.createServer()
config = require "./config"

everyauth.github
  .appId(config.appId)
  .appSecret(config.appSecret)
  .findOrCreateUser (session, accessToken, accessTokenExtra, githubUserMetadata) ->
    console.log "findOrCreateUser", githubUserMetadata
    githubUserMetadata
  .redirectPath("/")

app.configure ->
  app.use express.bodyParser()
  app.use express.cookieParser()
  app.use express.session({secret: config.sessionSecret})
  app.use everyauth.middleware()

app.get '/', (req, res) ->
  res.send "Hello world"
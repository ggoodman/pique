doctype 5
html ->
  head ->
    script src: "https://ajax.googleapis.com/ajax/libs/jquery/1.7.0/jquery.min.js"
    script src: "lib/ace.js"
    script src: "lib/coffeekup.js"
    script src: "lib/ccss.js"
    script src: "lib/bootstrap-modal.js"
    script src: "lib/bootstrap-dropdown.js"
    script "github_token = \"#{@everyauth.github.accessToken}\";" if @everyauth.loggedIn
    script @javascript # Express-Expose
    link {rel: "stylesheet", type: "text/css", href: "style/bootstrap.css"}
    style """
      .login.github {
        background: url("img/github_blue_black_cat_32.png");
        width: 32px;
        height: 32px;
      }
    """
      
    coffeescript ->
      templates =
        gist: ->
          div ".row.well", ->
            div ".span2", ->
              ul ".media-grid", ->
                li ->
                  a href: "http://github.com/#{@user.login}", ->
                    img {width: "90px", height: "90px", src: @user.avatar_url}
                    center @user.login
            div ".span8", ->
              h3 h(@description) or "Gist: #{@id}"
              for filename, details of @files
                a {href: details.raw_url}, details.filename
                  
      $render = (name, data) ->
        console.log "Data", data
        data.hardcode =
          ccss: (styles) -> ccss(styles)
        $ CoffeeKup.render templates[name], data
    
      $ ->
        request =
          success: (data) ->
            for gist in data
              $render('gist', gist).appendTo("#main")
        
        if github_token? then request.data = access_token: github_token

        #$.ajax "https://api.github.com/gists", request
        
  body ->
    div ".topbar", ->
      div ".fill", ->
        div ".container", ->
          h3 ".brand", "Pique"
          if @everyauth.loggedIn
            ul ".nav.secondary-nav", ->
              li ".dropdown", "data-dropdown": "dropdown", ->
                a ".dropdown-toggle", {href: "#"}, @everyauth.github.user.login
                ul ".dropdown-menu", ->
                  li -> a href: "/logout", -> "Logout"
            p ".pull-right", "Logged in as"
          else
            p ".pull-right", ->
              span "Not logged in "
              a href: "/auth/github", "Log in"
    div ".container", ->
      div ".content", ->
        div ".page-header", ->
          h1 "Content"
        
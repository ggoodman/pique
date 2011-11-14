$ ->
  request =
    success: (data) ->
      list =  $("#main ul")
      list = $("<ul>").appendTo("#main") unless list.size()
      for gist in data
        user = $("<div>")
        gravater = $("<img>", {src: gist.user.avatar_url, title: gist.user.login}).appendTo(user)
        login = $("<span>").text(gist.user.login).appendTo(user)
        
        a = $("<a>", {href: gist.html_url, text: gist.description or "Untitled"})
        li = $("<li>").append(user).append(a).appendTo(list)
      console.log "Received data", data, $("#data")
      $("#data").text(JSON.stringify(data))
  
  if github_token? then request.data = access_token: github_token
  
  $.ajax "https://api.github.com/gists", request

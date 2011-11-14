(function() {
  $(function() {
    var request;
    request = {
      success: function(data) {
        var a, gist, gravater, li, list, login, user, _i, _len;
        list = $("#main ul");
        if (!list.size()) {
          list = $("<ul>").appendTo("#main");
        }
        for (_i = 0, _len = data.length; _i < _len; _i++) {
          gist = data[_i];
          user = $("<div>");
          gravater = $("<img>", {
            src: gist.user.avatar_url,
            title: gist.user.login
          }).appendTo(user);
          login = $("<span>").text(gist.user.login).appendTo(user);
          a = $("<a>", {
            href: gist.html_url,
            text: gist.description || "Untitled"
          });
          li = $("<li>").append(user).append(a).appendTo(list);
        }
        console.log("Received data", data, $("#data"));
        return $("#data").text(JSON.stringify(data));
      }
    };
    if (typeof github_token !== "undefined" && github_token !== null) {
      request.data = {
        access_token: github_token
      };
    }
    return $.ajax("https://api.github.com/gists", request);
  });
}).call(this);

if Meteor.isClient
  Router.configure
    layoutTemplate: "layout"

  Router.map ->
    @route "home",
      path: "/"
      template: "home"

  Router.map ->
    @route "hackathon",
      path: "/:hackathon_name"
      template: "hackathon"

  Template.hackathon.helpers
    name: -> Router.current().path[1..]

  Template.tweet_sidebar.rendered = ->
    # stock twitter widget code
    ((d, s, id) ->
      fjs = d.getElementsByTagName(s)[0]
      p = (if /^http:/.test(d.location) then "http" else "https")
      unless d.getElementById(id)
        js = d.createElement(s)
        js.id = id
        js.src = "#{p}://platform.twitter.com/widgets.js"
        fjs.parentNode.insertBefore(js, fjs)
    )(document, "script", "twitter-wjs")
    # / stock twitter code

if Meteor.isServer
  Meteor.startup -> # code to run on server at startup

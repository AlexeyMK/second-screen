Hackathons = new Meteor.Collection("hackathons")
# faking for now, later use
# https://www.hackerleague.org/api/v1/hackathons.json
Hacks = new Meteor.Collection("hacks")
# to import: https://www.hackerleague.org/api/v1/hackathons/51f622218cf5b76a9600004f/hacks.json
# yale: https://www.hackerleague.org/api/v1/hackathons/51f43f3b36944f2aa8000125/hacks.json

if Meteor.isClient
  window.Hacks = Hacks #TEMP as fuck
  window.Hackathons = Hackathons #TEMP as fuck

  Router.configure
    layoutTemplate: "layout"

  Router.map ->
    @route "home",
      path: "/"
      template: "home"

  Router.map ->
    @route "scraper",
      path: "/scrape/:hackerleague_id"
      template: "scrape"
      before: ->
        hacks_url = "https://www.hackerleague.org/api/v1/hackathons/#{@params.hackerleague_id}/hacks.json"
        hackathon_url = "https://www.hackerleague.org/api/v1/hackathons.json"

        # import 100 hackathons, cause why not
        Meteor.http.get hackathon_url, (error, result) =>
          if error
            Session.set "couldn't get first page of hackathons, #{error}"
          else
            # temp: kill first
            Hackathons.find().forEach (hackathon) ->
              Hackathons.remove(hackathon._id)
            for hl_hackathon in result.data
              Hackathons.insert
                hackerleague: hl_hackathon
                name: hl_hackathon.name
                slug: hl_hackathon.slug

        # import this hackathon's hacks
        Meteor.http.get hacks_url, (error, result) =>
          Session.set "scrape_result", ""
          if error
            Session.set "scrape_result", "Couldn't scrape due to #{error}"
          else
            Session.set "scrape_result", "Adding #{result.data.length} hacks"
            # temporary: delete all old hacks
            Hacks.find(hackerleague_hackathonid: @params.hackerleague_id
            ).forEach (hack) ->
              Hacks.remove(hack._id)

            for hackerleague_hack in result.data
              hack =
                hackerleague: hackerleague_hack
                hackerleague_hackathonid: @params.hackerleague_id
              Hacks.insert hack
            Session.set "scrape_result", "Done! Added #{result.data.length} hacks"


  Router.map ->
    @route "hackathon",
      path: "/:hackathon_slug"
      template: "hackathon"
      before: ->
        Session.set "hackathon", Hackathons.findOne(slug: @params.hackathon_slug)

  Template.scrape.helpers
    result: -> Session.get("scrape_result") or "Still scrapin"

  Template.hackathon.helpers
    name: -> Session.get("hackathon")?.name
    demoing_now: -> null
    hackathon: -> Session.get "hackathon"

  Template.enter_team.settings = ->
    position: "bottom"
    limit: 5
    rules: [
      token: ""
      collection: Hacks
      field: "hackerleague.name"
      template: Template.hack_autocomplete
    ]

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

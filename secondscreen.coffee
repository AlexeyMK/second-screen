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
      action: ->
        this.redirect("/hackprinceton-fall-2013")

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
                liked_by: []
                would_be_used_by: []
                voted_by: []
              Hacks.insert hack
            Session.set "scrape_result", "Done! Added #{result.data.length} hacks"


  Router.map ->
    @route "hackathon",
      path: "/:hackathon_slug"
      template: "hackathon"
      before: ->
        Session.set "hackathon", Hackathons.findOne(slug: @params.hackathon_slug)

  get_hack = -> Hacks.findOne(Session.get('current_hack')._id)

  Template.scrape.helpers
    result: -> Session.get("scrape_result") or "Still scrapin"

  Template.hackathon.helpers
    name: -> Session.get("hackathon")?.name
    demoing_now: -> Session.get "current_hack"
    hackathon: -> Session.get "hackathon"

  Template.enter_team.settings = ->
    position: "bottom"
    limit: 5
    rules: [
      token: "^"
      include_token: false
      collection: Hacks
      field: "hackerleague.name"
      template: Template.hack_autocomplete
    ]
    onSelected: (picked_name) ->
      hack = Hacks.findOne("hackerleague.name": picked_name)
      if not hack
        console.error("Couldn't find selected hack: #{picked_name}")
      Session.set "current_hack", hack

  Template.hack_actions.events =
    'click button': (event) ->
      Meteor.call "toggle_action",
        event.toElement.id, Session.get("current_hack")._id
  Template.hack_actions.helpers
    'count': (store) ->
      get_hack()?[store]?.length or 0
    'user_did_action': (action) ->
      Meteor.userId() in (get_hack()?[action] or [])

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
    #
if Meteor.isServer
  Meteor.methods
    toggle_action: (action, hack_id) ->
      ACTION_NAMES = {
        like: "liked_by"
        vote: "voted_by"
        woulduse: "would_be_used_by"
      }
      store = ACTION_NAMES[action]
      lookup_dict = {}
      lookup_dict[store] = @userId
      hack = Hacks.findOne(hack_id)
      if @userId in hack[store]
        # remove from liked list
        Hacks.update(hack_id, { $pull: lookup_dict})
      else
        Hacks.update(hack_id, { $push: lookup_dict})

  Meteor.startup -> # code to run on server at startup

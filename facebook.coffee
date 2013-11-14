# first, remove configuration entry in case service is already configured
if Meteor.isServer
  # for localhost:3002
  Meteor.startup ->
  Accounts.loginServiceConfiguration.remove
    service: "facebook"
  Accounts.loginServiceConfiguration.insert
    service: "facebook",
    appId: "1374427239470034",
    secret: "19f2da3279741d86a174e5c3cacdd38e"

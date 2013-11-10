if (Meteor.isClient) {
  Template.hello.greeting = function () {
    return "Welcome to secondscreen.";
  };

  Template.tweet_sidebar.rendered = function() {
    // stock twitter widget code
    ! function (d, s, id) {
        var js, fjs = d.getElementsByTagName(s)[0],
            p = /^http:/.test(d.location) ? 'http' : 'https';
        if (!d.getElementById(id)) {
            js = d.createElement(s);
            js.id = id;
            js.src = p + "://platform.twitter.com/widgets.js";
            fjs.parentNode.insertBefore(js, fjs);
        }
    }(document, "script", "twitter-wjs");
  };
  Router.configure({
    layoutTemplate: 'layout'
  });

  Router.map(function () {
    this.route('home', {
      path: '/',
      template: 'home'
    });

    this.route('posts', {
      path: '/posts'
    });

    this.route('post', {
      path: '/posts/:_id',

      load: function () {
        // called on first load
      },

      // before hooks are run before your action
      before: [
        function () {
          this.subscribe('post', this.params._id).wait();
          this.subscribe('posts'); // don't wait
        },

        function () {
          // we're done waiting on all subs
          if (this.ready()) {
            NProgress.done();
          } else {
            NProgress.start();
            this.stop(); // stop downstream funcs from running
          }
        }
      ],

      action: function () {
        var params = this.params; // including query params
        var hash = this.hash;
        var isFirstRun = this.isFirstRun;

        this.render(); // render all
        this.render('specificTemplate', {to: 'namedYield'});
      },

      unload: function () {
        // before a new route is run
      }
    }); // end post route
  });
}

if (Meteor.isServer) {
  Meteor.startup(function () {
    // code to run on server at startup
  });
}

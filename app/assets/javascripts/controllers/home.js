'use strict';

Application.Controllers.controller('HomeController', ['$scope', '$stateParams', 'homeContentPromise',
  function ($scope, $stateParams, homeContentPromise) {
  /* PUBLIC SCOPE */

    // Home page HTML content
    $scope.homeContent = null;

    /* PRIVATE SCOPE */

    /**
   * Kind of constructor: these actions will be realized first when the controller is loaded
   */
    const initialize = function () {
      // if we recieve a token to reset the password as GET parameter, trigger the
      // changePassword modal from the parent controller
      if ($stateParams.reset_password_token) {
        return $scope.$parent.editPassword($stateParams.reset_password_token);
      }

      // We set the home page content, with the directives replacing the placeholders
      $scope.homeContent = insertDirectives(homeContentPromise.setting.value);
    };

    const insertDirectives = function (html) {
      const node = document.createElement('div');
      node.innerHTML = html.trim();

      const newsNode = node.querySelector('div#news');
      if (newsNode) {
        const news = document.createElement('news');
        newsNode.parentNode.replaceChild(news, newsNode);
      }

      const projectsNode = node.querySelector('div#projects');
      if (projectsNode) {
        const projects = document.createElement('projects');
        projectsNode.parentNode.replaceChild(projects, projectsNode);
      }

      const twitterNode = node.querySelector('div#twitter');
      if (twitterNode) {
        const twitter = document.createElement('twitter');
        twitterNode.parentNode.replaceChild(twitter, twitterNode);
      }

      const membersNode = node.querySelector('div#members');
      if (membersNode) {
        const members = document.createElement('members');
        membersNode.parentNode.replaceChild(members, membersNode);
      }

      const eventsNode = node.querySelector('div#events');
      if (eventsNode) {
        const events = document.createElement('events');
        eventsNode.parentNode.replaceChild(events, eventsNode);
      }

      return node.outerHTML;
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

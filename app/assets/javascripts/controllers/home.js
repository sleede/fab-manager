'use strict';

Application.Controllers.controller('HomeController', ['$scope', '$stateParams', 'homeContentPromise', 'uiTourService',
  function ($scope, $stateParams, homeContentPromise, uiTourService) {
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

      // setup the tour
      const uitour = uiTourService.getTour();
      uitour.start();
    };

    const insertDirectives = function (html) {
      const node = document.createElement('div');
      node.innerHTML = html.trim();

      node.querySelectorAll('div#news').forEach((newsNode) => {
        const news = document.createElement('news');
        newsNode.parentNode.replaceChild(news, newsNode);
      });

      node.querySelectorAll('div#projects').forEach((projectsNode) => {
        const projects = document.createElement('projects');
        projectsNode.parentNode.replaceChild(projects, projectsNode);
      });

      node.querySelectorAll('div#twitter').forEach((twitterNode) => {
        const twitter = document.createElement('twitter');
        twitterNode.parentNode.replaceChild(twitter, twitterNode);
      });

      node.querySelectorAll('div#members').forEach((membersNode) => {
        const members = document.createElement('members');
        membersNode.parentNode.replaceChild(members, membersNode);
      });

      node.querySelectorAll('div#events').forEach((eventsNode) => {
        const events = document.createElement('events');
        eventsNode.parentNode.replaceChild(events, eventsNode);
      });

      return node.outerHTML;
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

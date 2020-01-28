'use strict';

Application.Controllers.controller('HomeController', ['$scope', '$stateParams', 'homeContentPromise', 'uiTourService', '_t',
  function ($scope, $stateParams, homeContentPromise, uiTourService, _t) {
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
      uitour.createStep({
        selector: 'head',
        stepId: 'welcome',
        order: 0,
        title: _t('app.public.tour.welcome.title'),
        content: _t('app.public.tour.welcome.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.nav-primary li.home-link',
        stepId: 'home',
        order: 1,
        title: _t('app.public.tour.home.title'),
        content: _t('app.public.tour.home.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary li.reserve-machine-link',
        stepId: 'machines',
        order: 2,
        title: _t('app.public.tour.machines.title'),
        content: _t('app.public.tour.machines.content'),
        placement: 'right'
      });
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

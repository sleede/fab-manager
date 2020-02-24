'use strict';

Application.Controllers.controller('HomeController', ['$scope', '$stateParams', 'homeContentPromise', 'Member', 'uiTourService', '_t',
  function ($scope, $stateParams, homeContentPromise, Member, uiTourService, _t) {
  /* PUBLIC SCOPE */

    // Home page HTML content
    $scope.homeContent = null;

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // if we receive a token to reset the password as GET parameter, trigger the
      // changePassword modal from the parent controller
      if ($stateParams.reset_password_token) {
        return $scope.$parent.editPassword($stateParams.reset_password_token);
      }

      // We set the home page content, with the directives replacing the placeholders
      $scope.homeContent = insertDirectives(homeContentPromise.setting.value);

      // setup the tour for admins
      if ($scope.currentUser && $scope.currentUser.role === 'admin') {
        setupWelcomeTour();
        // listen the $destroy event of the controller to remove the F1 key binding
        $scope.$on('$destroy', function () {
          window.removeEventListener('keydown', handleF1);
        });
      }
    };

    /**
     * Parse the provided html and replace the elements with special IDs (#news, #projects, #twitter, #members, #events)
     * by their respective angular directives
     * @param html {String} a valid html string, as defined by the summernote editor in admin/settings/home_page
     * @returns {string} a valid html string containing angular directives for the specified plugins
     */
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

    /**
     * Setup the feature-tour for the home page that will present an overview of the whole app.
     * This is intended as a contextual help.
     */
    const setupWelcomeTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('welcome');
      // add the steps
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.public.tour.welcome.title'),
        content: _t('app.public.tour.welcome.content'),
        placement: 'bottom',
        orphan: true
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
      uitour.createStep({
        selector: '.nav-primary li.reserve-training-link',
        stepId: 'trainings',
        order: 3,
        title: _t('app.public.tour.trainings.title'),
        content: _t('app.public.tour.trainings.content'),
        placement: 'right'
      });
      if (!Fablab.withoutSpaces) {
        uitour.createStep({
          selector: '.nav-primary li.reserve-space-link',
          stepId: 'spaces',
          order: 4,
          title: _t('app.public.tour.spaces.title'),
          content: _t('app.public.tour.spaces.content'),
          placement: 'right'
        });
      }
      uitour.createStep({
        selector: '.nav-primary li.reserve-event-link',
        stepId: 'events',
        order: 5,
        title: _t('app.public.tour.events.title'),
        content: _t('app.public.tour.events.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary li.public-calendar-link',
        stepId: 'calendar',
        order: 6,
        title: _t('app.public.tour.calendar.title'),
        content: _t('app.public.tour.calendar.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary li.projects-gallery-link',
        stepId: 'projects',
        order: 7,
        title: _t('app.public.tour.projects.title'),
        content: _t('app.public.tour.projects.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary li.plans-link',
        stepId: 'plans',
        order: 8,
        title: _t('app.public.tour.plans.title'),
        content: _t('app.public.tour.plans.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary .admin-section',
        stepId: 'admin',
        order: 9,
        title: _t('app.public.tour.admin.title'),
        content: _t('app.public.tour.admin.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.navbar.header li.about-page-link',
        stepId: 'about',
        order: 10,
        title: _t('app.public.tour.about.title'),
        content: _t('app.public.tour.about.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.navbar.header li.notification-center-link',
        stepId: 'notifications',
        order: 11,
        title: _t('app.public.tour.notifications.title'),
        content: _t('app.public.tour.notifications.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.navbar.header li.user-menu-dropdown',
        stepId: 'profile',
        order: 12,
        title: _t('app.public.tour.profile.title'),
        content: _t('app.public.tour.profile.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.app-generator .app-version',
        stepId: 'version',
        order: 13,
        title: _t('app.public.tour.version.title'),
        content: _t('app.public.tour.version.content'),
        placement: 'top'
      });
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 14,
        title: _t('app.public.tour.conclusion.title'),
        content: _t('app.public.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('welcome') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'welcome' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if ($scope.currentUser.profile.tours.indexOf('welcome') < 0) {
        uitour.start();
      }
      // start this tour when an user press F1 - this is contextual help
      window.addEventListener('keydown', handleF1);
    };

    /**
     * Callback used to trigger the feature tour when the user press the F1 key.
     * @param e {KeyboardEvent}
     */
    const handleF1 = function (e) {
      if (e.key === 'F1') {
        e.preventDefault();
        const tour = uiTourService.getTourByName('welcome');
        if (tour) { tour.start(); }
      }
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

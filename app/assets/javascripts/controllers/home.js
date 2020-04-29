'use strict';

Application.Controllers.controller('HomeController', ['$scope', '$stateParams', '$translatePartialLoader', 'AuthService', 'settingsPromise', 'Member', 'uiTourService', '_t', 'Help',
  function ($scope, $stateParams, $translatePartialLoader, AuthService, settingsPromise, Member, uiTourService, _t, Help) {
  /* PUBLIC SCOPE */

    // Home page HTML content
    $scope.homeContent = null;

    // Status of the components in the home page (exists or not?)
    $scope.status = {
      news: false,
      projects: false,
      twitter: false,
      members: false,
      events: false
    };

    /**
     * Setup the feature-tour for the home page. (admins only)
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupHomeTour = function () {
      if (AuthService.isAuthorized(['admin', 'manager'])) {
        // Workaround for the following bug: as a manager, when the feature tour is shown, the translations keys are not
        // interpreted. This is an ugly hack, but we can't do better for now because angular-ui-tour does not support
        // removing steps (this would allow us to recreate the steps when the translations are loaded), and we can't use
        // promises with _t's translations (this would be a very big refactoring)
        setTimeout(setupWelcomeTour, 1000);
      }
    };

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
      $scope.homeContent = insertDirectives(settingsPromise.home_content);

      // for admins, setup the tour on login
      $scope.$watch('currentUser', function (newValue, oldValue) {
        if (!oldValue && newValue && newValue.role === 'admin') {
          const uitour = uiTourService.getTourByName('welcome');
          if (!uitour.hasStep()) {
            setupWelcomeTour();
          }
        }
      });
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
        $scope.status.news = true;
      });

      node.querySelectorAll('div#projects').forEach((projectsNode) => {
        const projects = document.createElement('projects');
        projectsNode.parentNode.replaceChild(projects, projectsNode);
        $scope.status.projects = true;
      });

      node.querySelectorAll('div#twitter').forEach((twitterNode) => {
        const twitter = document.createElement('twitter');
        twitterNode.parentNode.replaceChild(twitter, twitterNode);
        $scope.status.twitter = true;
      });

      node.querySelectorAll('div#members').forEach((membersNode) => {
        const members = document.createElement('members');
        membersNode.parentNode.replaceChild(members, membersNode);
        $scope.status.members = true;
      });

      node.querySelectorAll('div#events').forEach((eventsNode) => {
        const events = document.createElement('events');
        eventsNode.parentNode.replaceChild(events, eventsNode);
        $scope.status.events = true;
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
        title: _t('app.public.tour.welcome.welcome.title'),
        content: _t('app.public.tour.welcome.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.nav-primary li.home-link',
        stepId: 'home',
        order: 1,
        title: _t('app.public.tour.welcome.home.title'),
        content: _t('app.public.tour.welcome.home.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary li.public-calendar-link',
        stepId: 'calendar',
        order: 2,
        title: _t('app.public.tour.welcome.calendar.title'),
        content: _t('app.public.tour.welcome.calendar.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary li.reserve-machine-link',
        stepId: 'machines',
        order: 3,
        title: _t('app.public.tour.welcome.machines.title'),
        content: _t('app.public.tour.welcome.machines.content'),
        placement: 'right'
      });
      if (!Fablab.withoutSpaces) {
        uitour.createStep({
          selector: '.nav-primary li.reserve-space-link',
          stepId: 'spaces',
          order: 4,
          title: _t('app.public.tour.welcome.spaces.title'),
          content: _t('app.public.tour.welcome.spaces.content'),
          placement: 'right'
        });
      }
      uitour.createStep({
        selector: '.nav-primary li.reserve-training-link',
        stepId: 'trainings',
        order: 5,
        title: _t('app.public.tour.welcome.trainings.title'),
        content: _t('app.public.tour.welcome.trainings.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary li.reserve-event-link',
        stepId: 'events',
        order: 6,
        title: _t('app.public.tour.welcome.events.title'),
        content: _t('app.public.tour.welcome.events.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary li.projects-gallery-link',
        stepId: 'projects',
        order: 7,
        title: _t('app.public.tour.welcome.projects.title'),
        content: _t('app.public.tour.welcome.projects.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary li.plans-link',
        stepId: 'plans',
        order: 8,
        title: _t('app.public.tour.welcome.plans.title'),
        content: _t('app.public.tour.welcome.plans.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.nav-primary .admin-section',
        stepId: 'admin',
        order: 9,
        title: _t('app.public.tour.welcome.admin.title', { ROLE: _t(`app.public.common.${$scope.currentUser.role}`) }),
        content: _t('app.public.tour.welcome.admin.content'),
        placement: 'right'
      });
      uitour.createStep({
        selector: '.navbar.header li.about-page-link',
        stepId: 'about',
        order: 10,
        title: _t('app.public.tour.welcome.about.title'),
        content: _t('app.public.tour.welcome.about.content'),
        placement: 'bottom',
        popupClass: 'shift-right-40'
      });
      uitour.createStep({
        selector: '.navbar.header li.notification-center-link',
        stepId: 'notifications',
        order: 11,
        title: _t('app.public.tour.welcome.notifications.title'),
        content: _t('app.public.tour.welcome.notifications.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.navbar.header li.user-menu-dropdown',
        stepId: 'profile',
        order: 12,
        title: _t('app.public.tour.welcome.profile.title'),
        content: _t('app.public.tour.welcome.profile.content'),
        placement: 'bottom',
        popupClass: 'shift-left-80'
      });
      if ($scope.status.news && settingsPromise.home_blogpost) {
        uitour.createStep({
          selector: 'news',
          stepId: 'news',
          order: 13,
          title: _t('app.public.tour.welcome.news.title'),
          content: _t('app.public.tour.welcome.news.content'),
          placement: 'bottom'
        });
      }
      if ($scope.status.projects) {
        uitour.createStep({
          selector: 'projects',
          stepId: 'last_projects',
          order: 14,
          title: _t('app.public.tour.welcome.last_projects.title'),
          content: _t('app.public.tour.welcome.last_projects.content'),
          placement: 'right'
        });
      }
      if ($scope.status.twitter) {
        uitour.createStep({
          selector: 'twitter',
          stepId: 'last_tweet',
          order: 15,
          title: _t('app.public.tour.welcome.last_tweet.title'),
          content: _t('app.public.tour.welcome.last_tweet.content'),
          placement: 'left'
        });
      }
      if ($scope.status.members) {
        uitour.createStep({
          selector: 'members',
          stepId: 'last_members',
          order: 16,
          title: _t('app.public.tour.welcome.last_members.title'),
          content: _t('app.public.tour.welcome.last_members.content'),
          placement: 'left'
        });
      }
      if ($scope.status.events) {
        uitour.createStep({
          selector: 'events',
          stepId: 'next_events',
          order: 17,
          title: _t('app.public.tour.welcome.next_events.title'),
          content: _t('app.public.tour.welcome.next_events.content'),
          placement: 'top'
        });
      }
      uitour.createStep({
        selector: 'body',
        stepId: 'customize',
        order: 18,
        title: _t('app.public.tour.welcome.customize.title'),
        content: _t('app.public.tour.welcome.customize.content'),
        placement: 'bottom',
        orphan: 'true'
      });
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: '.app-generator .app-version',
          stepId: 'version',
          order: 19,
          title: _t('app.public.tour.welcome.version.title'),
          content: _t('app.public.tour.welcome.version.content'),
          placement: 'top'
        });
      }
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 20,
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
      if (Fablab.featureTourDisplay !== 'manual' && $scope.currentUser.profile.tours.indexOf('welcome') < 0) {
        uitour.start();
      }
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/* eslint-disable
    no-return-assign,
    no-undef,
*/
'use strict';

Application.Controllers.controller('AdminMachinesController', ['$scope', 'CSRF', 'growl', '$state', '_t', 'AuthService', 'settingsPromise', 'Member', 'uiTourService', 'machinesPromise', 'helpers',
  function ($scope, CSRF, growl, $state, _t, AuthService, settingsPromise, Member, uiTourService, machinesPromise, helpers) {
    /* PUBLIC SCOPE */

    // default tab: machines list
    $scope.tabs = { active: 0 };

    // the application global settings
    $scope.settings = settingsPromise;

    /**
     * Redirect the user to the machine details page
     */
    $scope.showMachine = function (machine) { $state.go('app.public.machines_show', { id: machine.slug }); };

    /**
     * Shows an error message forwarded from a child component
     */
    $scope.onError = function (message) {
      console.error(message);
      growl.error(message);
    };

    /**
     * Shows a success message forwarded from a child react components
     */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };

    /**
     * Open the modal dialog to log the user and resolves the returned promise when the logging process
     * was successfully completed.
     */
    $scope.onLoginRequest = function (e) {
      return new Promise((resolve, _reject) => {
        $scope.login(e, resolve);
      });
    };

    /**
     * Redirect the user to the training reservation page
     */
    $scope.onEnrollRequest = function (trainingId) {
      $state.go('app.logged.trainings_reserve', { id: trainingId });
    };

    /**
     * Callback to book a reservation for the current machine
     */
    $scope.reserveMachine = function (machine) {
      $state.go('app.logged.machines_reserve', { id: machine.slug });
    };

    $scope.canProposePacks = function () {
      return AuthService.isAuthorized(['admin', 'manager']) || !helpers.isUserValidationRequired($scope.settings, 'pack') || (helpers.isUserValidationRequired($scope.settings, 'pack') && helpers.isUserValidated($scope.currentUser));
    };

    /**
     * Setup the feature-tour for the machines page. (admins only)
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupMachinesTour = function () {
      // setup the tour for admins only
      if (AuthService.isAuthorized(['admin', 'manager'])) {
        // get the tour defined by the ui-tour directive
        const uitour = uiTourService.getTourByName('machines');
        if (AuthService.isAuthorized('admin')) {
          uitour.createStep({
            selector: 'body',
            stepId: 'welcome',
            order: 0,
            title: _t('app.public.tour.machines.welcome.title'),
            content: _t('app.public.tour.machines.welcome.content'),
            placement: 'bottom',
            orphan: true
          });
          if (machinesPromise.length > 0) {
            uitour.createStep({
              selector: '.machines-list .show-button',
              stepId: 'view',
              order: 1,
              title: _t('app.public.tour.machines.view.title'),
              content: _t('app.public.tour.machines.view.content'),
              placement: 'top'
            });
          }
        } else {
          uitour.createStep({
            selector: 'body',
            stepId: 'welcome_manager',
            order: 0,
            title: _t('app.public.tour.machines.welcome_manager.title'),
            content: _t('app.public.tour.machines.welcome_manager.content'),
            placement: 'bottom',
            orphan: true
          });
        }
        if (machinesPromise.length > 0) {
          uitour.createStep({
            selector: '.machines-list .reserve-button',
            stepId: 'reserve',
            order: 2,
            title: _t('app.public.tour.machines.reserve.title'),
            content: _t('app.public.tour.machines.reserve.content'),
            placement: 'top'
          });
        }
        uitour.createStep({
          selector: 'body',
          stepId: 'conclusion',
          order: 3,
          title: _t('app.public.tour.conclusion.title'),
          content: _t('app.public.tour.conclusion.content'),
          placement: 'bottom',
          orphan: true
        });
        // on tour end, save the status in database
        uitour.on('ended', function () {
          if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile_attributes.tours.indexOf('machines') < 0) {
            Member.completeTour({ id: $scope.currentUser.id }, { tour: 'machines' }, function (res) {
              $scope.currentUser.profile_attributes.tours = res.tours;
            });
          }
        });
        // if the user has never seen the tour, show him now
        if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile_attributes.tours.indexOf('machines') < 0) {
          uitour.start();
        }
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // set the authenticity tokens in the forms
      CSRF.setMetaTags();
    };

    // init the controller (call at the end !)
    return initialize();
  }

]);

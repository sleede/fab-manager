/* eslint-disable
    no-return-assign,
    no-undef,
*/
'use strict';

Application.Controllers.controller('CartController', ['$scope', 'CSRF', 'growl', '$state',
  function ($scope, CSRF, growl, $state) {
    /* PRIVATE SCOPE */

    /* PUBLIC SCOPE */

    /**
     * Open the modal dialog allowing the user to log into the system
     */
    $scope.userLogin = function () {
      setTimeout(() => {
        if (!$scope.isAuthenticated()) {
          $scope.login();
          $scope.$apply();
        }
      }, 50);
    };

    /**
     * Overlap global function to allow the user to navigate to the previous screen
     * If no previous $state were recorded, navigate to the project list page
     */
    $scope.backPrevLocation = function (event) {
      event.preventDefault();
      event.stopPropagation();
      if ($state.prevState === '') {
        $state.prevState = 'app.public.store';
      }
      window.history.back();
    };

    /**
     * Callback triggered in case of error
     */
    $scope.onError = (message) => {
      growl.error(message);
    };

    /**
     * Callback triggered in case of success
     */
    $scope.onSuccess = (message) => {
      growl.success(message);
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

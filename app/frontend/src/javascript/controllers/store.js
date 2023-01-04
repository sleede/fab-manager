'use strict';

Application.Controllers.controller('StoreController', ['$scope', 'CSRF', 'growl', '$uiRouter',
  function ($scope, CSRF, growl, $uiRouter) {
    /* PUBLIC SCOPE */

    // the following item is used by the Store component to store the filters in the URL
    $scope.uiRouter = $uiRouter;

    /**
     * Callback triggered in case of error
     */
    $scope.onError = (message) => {
      console.error(message);
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

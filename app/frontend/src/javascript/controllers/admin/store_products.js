/* eslint-disable
    no-return-assign,
    no-undef,
*/
'use strict';

Application.Controllers.controller('AdminStoreProductController', ['$scope', 'CSRF', 'growl', '$state', '$transition$', '$uiRouter',
  function ($scope, CSRF, growl, $state, $transition$, $uiRouter) {
    /* PUBLIC SCOPE */
    $scope.productId = $transition$.params().id;

    // the following item is used by the UnsavedFormAlert component to detect a page change
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

    /**
     * Click Callback triggered in case of back products list
     */
    $scope.backProductsList = (event) => {
      event.preventDefault();
      event.stopPropagation();
      if ($state.prevState === '') {
        $state.prevState = 'app.admin.store.products';
      }
      window.history.back();
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

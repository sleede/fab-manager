/* eslint-disable
    no-return-assign,
    no-undef,
*/
'use strict';

Application.Controllers.controller('AdminStoreController', ['$scope', 'CSRF', 'growl', '$state', '$uiRouter',
  function ($scope, CSRF, growl, $state, $uiRouter) {
    /* PRIVATE SCOPE */
    // Map of tab state and index
    const TABS = {
      'app.admin.store.settings': 0,
      'app.admin.store.products': 1,
      'app.admin.store.categories': 2,
      'app.admin.store.orders': 3
    };

    /* PUBLIC SCOPE */
    // default tab: products
    $scope.tabs = {
      active: TABS[$state.current.name]
    };

    // the following item is used by the Products component to save/restore filters in the URL
    $scope.uiRouter = $uiRouter;

    /**
     * Callback triggered in click tab
     */
    $scope.selectTab = () => {
      setTimeout(function () {
        const currentTab = _.keys(TABS)[$scope.tabs.active];
        if (currentTab !== $state.current.name) {
          $state.go(currentTab, { location: true, notify: false, reload: false });
        }
      });
    };

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

'use strict';

Application.Controllers.controller('ChildrenController', ['$scope', 'memberPromise', 'growl',
  function ($scope, memberPromise, growl) {
    // Current user's profile
    $scope.user = memberPromise;

    /**
     * Callback used to display a error message
     */
    $scope.onError = function (message) {
      console.error(message);
      growl.error(message);
    };

    /**
     * Callback used to display a success message
     */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };
  }
]);

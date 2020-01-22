'use strict';

Application.Controllers.controller('HomeController', ['$scope', '$stateParams', 'homeContentPromise',
  function ($scope, $stateParams, homeContentPromise) {
  /* PUBLIC SCOPE */

    // Home page HTML content
    $scope.homeContent = homeContentPromise;

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
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

'use strict';

Application.Controllers.controller('HomeController', ['$scope', '$stateParams', 'upcomingEventsPromise',
  function ($scope, $stateParams, upcomingEventsPromise) {
  /* PUBLIC SCOPE */

    // The closest upcoming events
    $scope.upcomingEvents = upcomingEventsPromise;

    /**
   * Test if the provided event run on a single day or not
   * @param event {Object} single event from the $scope.upcomingEvents array
   * @returns {boolean} false if the event runs on more that 1 day
   */
    $scope.isOneDayEvent = event => moment(event.start_date).isSame(event.end_date, 'day');

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

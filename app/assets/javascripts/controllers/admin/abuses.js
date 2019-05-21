/**
 * Controller used in abuses management page
 */
Application.Controllers.controller('AbusesController', ['$scope', '$state', 'Abuse', 'abusesPromise', 'growl', '_t',
  function ($scope, $state, Abuse, abusesPromise, growl, _t) {
    /* PUBLIC SCOPE */

    // List of all reported abuses
    $scope.abuses = [];

    /* PRIVATE SCOPE */
    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // we display only abuses related to projects
      $scope.abuses = abusesPromise.abuses.filter(a => a.signaled_type === 'Project');
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

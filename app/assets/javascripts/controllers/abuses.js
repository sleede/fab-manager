/**
 * Controller used in abuses management page
 */
Application.Controllers.controller('AbusesController', ['$scope', '$state', 'Abuse', 'abusesPromise', 'growl', '_t',
  function ($scope, $state, Abuse, abusesPromise, growl, _t) {
    // List of all reported abuses
    $scope.abuses = abusesPromise;
  }
]);

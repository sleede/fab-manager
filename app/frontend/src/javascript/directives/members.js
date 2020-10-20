Application.Directives.directive('members', [ 'Member',
  function (Member) {
    return ({
      restrict: 'E',
      templateUrl: '/home/members.html',
      link ($scope, element, attributes) {
        // The last registered members who confirmed their addresses
        $scope.lastMembers = null;

        // constructor
        const initialize = function () {
          Member.lastSubscribed({ limit: 4 }, function (data) {
            $scope.lastMembers = data;
          })
        };

        // !!! MUST BE CALLED AT THE END of the directive
        return initialize();
      }
    });
  }
]);

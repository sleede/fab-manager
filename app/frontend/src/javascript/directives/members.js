Application.Directives.directive('members', ['Member', 'Setting',
  function (Member, Setting) {
    return ({
      restrict: 'E',
      resolve: {
        settingsPromise: ['Setting', function (Setting) {
          return Setting.query({ names: "['public_registrations']" }).$promise;
        }]
      },
      templateUrl: '/home/members.html',
      link ($scope, element, attributes) {
        // The last registered members who confirmed their addresses
        $scope.lastMembers = null;

        // constructor
        const initialize = function () {
          Member.lastSubscribed({ limit: 4 }, function (data) {
            $scope.lastMembers = data;
          });
          Setting.query({ names: "['public_registrations']" }, function (data) {
            // is public registrations allowed?
            $scope.publicRegistrations = (data.public_registrations !== 'false');
          });
        };

        // !!! MUST BE CALLED AT THE END of the directive
        return initialize();
      }
    });
  }
]);

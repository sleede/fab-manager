Application.Directives.directive('projects', [ 'Project',
  function (Project) {
    return ({
      restrict: 'E',
      template: require('../../../../templates/home/projects.html'),
      link ($scope, element, attributes) {
        // The last projects published/documented on the platform
        $scope.lastProjects = null;

        // The default slide shown in the carousel
        $scope.activeSlide = 0;

        // constructor
        const initialize = function () {
          Project.lastPublished(function (data) {
            $scope.lastProjects = data;
          })
        };

        // !!! MUST BE CALLED AT THE END of the directive
        return initialize();
      }
    });
  }
]);

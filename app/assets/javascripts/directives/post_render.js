Application.Directives.directive('postRender', [ '$timeout',
  function ($timeout) {
    return ({
      restrict: 'A',
      terminal: false,
      transclude: false,
      link: function (scope, element, attrs) {
        $timeout(scope[attrs.postRender], 0);
      }
    });
  }
]);

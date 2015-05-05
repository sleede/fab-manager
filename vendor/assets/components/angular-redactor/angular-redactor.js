(function () {
  'use strict';

  /**
   * usage: <textarea ng-model="content" redactor></textarea>
   *
   *    additional options:
   *      redactor: hash (pass in a redactor options hash)
   *
   */
  angular.module('angular-redactor', [])
    .directive("redactor", ['$timeout', function ($timeout) {
      return {
        restrict: 'A',
        require: "ngModel",
        link: function (scope, element, attrs, ngModel) {

          var updateModel = function updateModel(value) {
              scope.$apply(function () {
                ngModel.$setViewValue(value);
              });
            },
            options = {
              changeCallback: updateModel
            },
            additionalOptions = attrs.redactor ?
                                scope.$eval(attrs.redactor) : {},
            editor,
            $_element = angular.element(element);

          angular.extend(options, additionalOptions);

          // put in timeout to avoid $digest collision.  call render() to
          // set the initial value.
          $timeout(function () {
            editor = $_element.redactor(options);
            ngModel.$render();
          });

          ngModel.$render = function () {
            if (angular.isDefined(editor)) {
              $timeout(function() {
                $_element.redactor('set', ngModel.$viewValue || '');
              });
            }
          };
        }
      };
    }]);
})();


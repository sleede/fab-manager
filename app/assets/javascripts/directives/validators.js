/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Directives.directive('url', [ function() {
  const URL_REGEXP = /^(https?:\/\/)([\da-z\.-]+)\.([-a-z0-9\.]{2,30})([\/\w \.-]*)*\/?$/;
  return {
    require: 'ngModel',
    link(scope, element, attributes, ctrl) {
      return ctrl.$validators.url = function(modelValue, viewValue) {
        if (ctrl.$isEmpty(modelValue)) {
          return true;
        }
        if (URL_REGEXP.test(viewValue)) {
          return true;
        }

        // otherwise, this is invalid
        return false;
      };
    }
  };
}
]);


Application.Directives.directive('endpoint', [ function() {
  const ENDPOINT_REGEXP = /^\/?([-._~:?#\[\]@!$&'()*+,;=%\w]+\/?)*$/;
  return {
    require: 'ngModel',
    link(scope, element, attributes, ctrl) {
      return ctrl.$validators.endpoint = function(modelValue, viewValue) {
        if (ctrl.$isEmpty(modelValue)) {
          return true;
        }
        if (ENDPOINT_REGEXP.test(viewValue)) {
          return true;
        }

        // otherwise, this is invalid
        return false;
      };
    }
  };
}
]);
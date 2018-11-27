'use strict';

Application.Services.factory('_t', ['$filter', function ($filter) {
  return function (key, interpolation, options) {
    if (interpolation == null) { interpolation = undefined; }
    if (options == null) { options = undefined; }
    return $filter('translate')(key, interpolation, options);
  };
}]);

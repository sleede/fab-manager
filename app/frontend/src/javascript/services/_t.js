'use strict';

Application.Services.factory('_t', ['$translate', function ($translate) {
  return function (key, interpolations) {
    if (interpolations == null) { interpolations = undefined; }
    return $translate.instant(key, interpolations);
  };
}]);

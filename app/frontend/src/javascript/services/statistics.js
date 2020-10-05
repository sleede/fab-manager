'use strict';

Application.Services.factory('Statistics', ['$resource', function ($resource) {
  return $resource('/api/statistics');
}]);

'use strict';

Application.Services.factory('Ical', ['$resource', function ($resource) {
  return $resource('/api/ical/externals');
}]);

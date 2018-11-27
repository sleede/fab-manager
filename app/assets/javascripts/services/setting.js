'use strict';

Application.Services.factory('Setting', ['$resource', function ($resource) {
  return $resource('/api/settings/:name',
    { name: '@name' }, {
      update: {
        method: 'PUT'
      },
      query: {
        isArray: false
      }
    }
  );
}]);

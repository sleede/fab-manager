'use strict';

Application.Services.factory('Price', ['$resource', function ($resource) {
  return $resource('/api/prices/:id',
    {}, {
      query: {
        isArray: true
      },
      update: {
        method: 'PUT'
      },
      compute: {
        method: 'POST',
        url: '/api/prices/compute',
        isArray: false
      }
    }
  );
}]);

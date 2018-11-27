'use strict';

Application.Services.factory('Event', ['$resource', function ($resource) {
  return $resource('/api/events/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      },
      upcoming: {
        method: 'GET',
        url: '/api/events/upcoming/:limit',
        params: { limit: '@limit' },
        isArray: true
      }
    }
  );
}]);

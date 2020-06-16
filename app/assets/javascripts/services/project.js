'use strict';

Application.Services.factory('Project', ['$resource', function ($resource) {
  return $resource('/api/projects/:id',
    { id: '@id' }, {
      lastPublished: {
        method: 'GET',
        url: '/api/projects/last_published',
        isArray: true
      },
      search: {
        method: 'GET',
        url: '/api/projects/search',
        isArray: false
      }
    }
  );
}]);

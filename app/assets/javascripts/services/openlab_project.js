'use strict';

Application.Services.factory('OpenlabProject', ['$resource', function ($resource) {
  return $resource('/api/openlab_projects/:id',
    { id: '@id' }, {
      query: {
        method: 'GET',
        isArray: false
      }
    }
  );
}]);

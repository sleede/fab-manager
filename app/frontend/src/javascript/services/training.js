'use strict';

Application.Services.factory('Training', ['$resource', function ($resource) {
  return $resource('/api/trainings/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      },
      availabilities: {
        method: 'GET',
        url: '/api/trainings/:id/availabilities'
      }
    }
  );
}]);

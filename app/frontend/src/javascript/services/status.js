'use strict';

Application.Services.factory('Status', ['$resource', function ($resource) {
  return $resource('/api/statuses/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

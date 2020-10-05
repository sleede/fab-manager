'use strict';

Application.Services.factory('Machine', ['$resource', function ($resource) {
  return $resource('/api/machines/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

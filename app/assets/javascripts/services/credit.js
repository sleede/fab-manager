'use strict';

Application.Services.factory('Credit', ['$resource', function ($resource) {
  return $resource('/api/credits/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

'use strict';

Application.Services.factory('Space', ['$resource', function ($resource) {
  return $resource('/api/spaces/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

'use strict';

Application.Services.factory('Admin', ['$resource', function ($resource) {
  return $resource('/api/admins/:id',
    { id: '@id' }, {
      query: {
        isArray: false
      }
    }
  );
}]);

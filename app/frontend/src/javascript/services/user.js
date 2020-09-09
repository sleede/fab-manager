'use strict';

Application.Services.factory('User', ['$resource', function ($resource) {
  return $resource('/api/users/:id',
    { id: '@id' }, {
      query: {
        isArray: false
      }
    }
  );
}]);

'use strict';

Application.Services.factory('User', ['$resource', function ($resource) {
  return $resource('/api/users',
    {}, {
      query: {
        isArray: false
      }
    }
  );
}]);

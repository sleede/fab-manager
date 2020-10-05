'use strict';

Application.Services.factory('Component', ['$resource', function($resource) {
  return $resource('/api/components/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

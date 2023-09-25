'use strict';

Application.Services.factory('Child', ['$resource', function ($resource) {
  return $resource('/api/children/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

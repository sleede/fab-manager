'use strict';

Application.Services.factory('Abuse', ['$resource', function ($resource) {
  return $resource('/api/abuses/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

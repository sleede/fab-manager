'use strict';

Application.Services.factory('Licence', ['$resource', function ($resource) {
  return $resource('/api/licences/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

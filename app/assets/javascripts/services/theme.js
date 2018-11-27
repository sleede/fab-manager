'use strict';

Application.Services.factory('Theme', ['$resource', function ($resource) {
  return $resource('/api/themes/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

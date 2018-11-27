'use strict';

Application.Services.factory('Tag', ['$resource', function ($resource) {
  return $resource('/api/tags/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

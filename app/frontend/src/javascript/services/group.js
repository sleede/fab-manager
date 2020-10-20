'use strict';

Application.Services.factory('Group', ['$resource', function ($resource) {
  return $resource('/api/groups/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

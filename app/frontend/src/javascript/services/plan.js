'use strict';

Application.Services.factory('Plan', ['$resource', function ($resource) {
  return $resource('/api/plans/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

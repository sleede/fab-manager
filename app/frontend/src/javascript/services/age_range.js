'use strict';

Application.Services.factory('AgeRange', ['$resource', function ($resource) {
  return $resource('/api/age_ranges/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

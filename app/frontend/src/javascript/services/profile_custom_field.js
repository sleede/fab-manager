'use strict';

Application.Services.factory('ProfileCustomField', ['$resource', function ($resource) {
  return $resource('/api/profile_custom_fields/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

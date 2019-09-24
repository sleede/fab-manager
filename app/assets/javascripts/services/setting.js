'use strict';

Application.Services.factory('Setting', ['$resource', function ($resource) {
  return $resource('/api/settings/:name',
    { name: '@name' }, {
      update: {
        method: 'PUT',
        transformRequest: (data) => {
          return angular.toJson({ setting: data });
        }
      },
      bulkUpdate: {
        url: '/api/settings/bulk_update',
        method: 'PATCH'
      },
      query: {
        isArray: false
      }
    }
  );
}]);

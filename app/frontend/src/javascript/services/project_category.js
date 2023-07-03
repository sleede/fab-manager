'use strict';

Application.Services.factory('ProjectCategory', ['$resource', function ($resource) {
  return $resource('/api/project_categories/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

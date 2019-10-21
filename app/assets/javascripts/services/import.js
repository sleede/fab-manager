'use strict';

Application.Services.factory('Import', ['$resource', function ($resource) {
  return $resource('/api/imports/:id',
    { id: '@id' }
  );
}]);

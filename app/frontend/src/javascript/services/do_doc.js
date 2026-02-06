'use strict';

Application.Services.factory('DoDoc', ['$resource', function ($resource) {
  return $resource('/api/do_docs/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

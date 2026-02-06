'use strict';

Application.Services.factory('DoDocProject', ['$resource', function ($resource) {
  return $resource('/api/do_doc_projects/:id',
    { id: '@id' }, {
      query: {
        method: 'GET',
        isArray: false
      }
    }
  );
}]);

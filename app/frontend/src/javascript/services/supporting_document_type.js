'use strict';

Application.Services.factory('SupportingDocumentType', ['$resource', function ($resource) {
  return $resource('/api/supporting_document_types/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

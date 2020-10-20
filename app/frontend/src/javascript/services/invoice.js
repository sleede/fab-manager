'use strict';

Application.Services.factory('Invoice', ['$resource', function ($resource) {
  return $resource('/api/invoices/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      },
      list: {
        url: '/api/invoices/list',
        method: 'POST',
        isArray: true
      },
      first: {
        url: '/api/invoices/first',
        method: 'GET'
      }
    }
  );
}]);

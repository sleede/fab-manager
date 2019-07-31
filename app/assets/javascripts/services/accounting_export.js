'use strict';

Application.Services.factory('AccountingExport', ['$resource', function ($resource) {
  return $resource('/api/accounting',
    {}, {
      export: {
        method: 'POST',
        url: '/api/accounting/export'
      }
    }
  );
}]);

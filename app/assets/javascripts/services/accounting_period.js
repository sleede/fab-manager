'use strict';

Application.Services.factory('AccountingPeriod', ['$resource', function ($resource) {
  return $resource('/api/accounting_period/:id',
    { id: '@id' }, {
      lastClosingEnd: {
        method: 'GET',
        url: '/api/accounting_period/last_closing_end'
      }
    }
  );
}]);

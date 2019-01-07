'use strict';

Application.Services.factory('AccountingPeriod', ['$resource', function ($resource) {
  return $resource('/api/accounting_periods/:id',
    { id: '@id' }, {
      lastClosingEnd: {
        method: 'GET',
        url: '/api/accounting_periods/last_closing_end'
      }
    }
  );
}]);

'use strict';

Application.Services.factory('Payment', ['$resource', function ($resource) {
  return $resource('/api/payments',
    {}, {
      confirm: {
        method: 'POST',
        url: '/api/payments/confirm_payment',
        isArray: false
      }
    }
  );
}]);

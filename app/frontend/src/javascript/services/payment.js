'use strict';

Application.Services.factory('Payment', ['$resource', function ($resource) {
  return $resource('/api/payments',
    {}, {
      confirm: {
        method: 'POST',
        url: '/api/payments/confirm_payment',
        isArray: false
      },
      onlinePaymentStatus: {
        method: 'GET',
        url: '/api/payments/online_payment_status'
      }
    }
  );
}]);

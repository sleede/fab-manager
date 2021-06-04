'use strict';

Application.Services.factory('LocalPayment', ['$resource', function ($resource) {
  return $resource('/api/local_payment',
    {}, {
      confirm: {
        method: 'POST',
        url: '/api/local_payment/confirm_payment',
        isArray: false
      }
    }
  );
}]);

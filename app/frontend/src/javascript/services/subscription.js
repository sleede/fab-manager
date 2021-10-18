'use strict';

Application.Services.factory('Subscription', ['$resource', function ($resource) {
  return $resource('/api/subscriptions/:id',
    { id: '@id' }, {
      payment_details: {
        url: '/api/subscriptions/:id/payment_details',
        method: 'GET'
      }
    }
  );
}]);

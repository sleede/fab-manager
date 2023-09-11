'use strict';

Application.Services.factory('Reservation', ['$resource', function ($resource) {
  return $resource('/api/reservations/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      },
      confirm_payment: {
        method: 'POST',
        url: '/api/reservations/confirm_payment',
        isArray: false
      }
    }
  );
}]);

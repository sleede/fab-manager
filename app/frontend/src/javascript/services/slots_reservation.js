'use strict';

Application.Services.factory('SlotsReservation', ['$resource', function ($resource) {
  return $resource('/api/slots_reservations/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      },
      cancel: {
        method: 'PUT',
        url: '/api/slots_reservations/:id/cancel'
      },
      validate: {
        method: 'PUT',
        url: '/api/slots_reservations/:id/validate'
      },
      invalidate: {
        method: 'PUT',
        url: '/api/slots_reservations/:id/invalidate'
      }
    }
  );
}]);

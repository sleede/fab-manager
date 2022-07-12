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
      }
    }
  );
}]);

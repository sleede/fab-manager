'use strict';

Application.Services.factory('Reservation', ['$resource', function ($resource) {
  return $resource('/api/reservations/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

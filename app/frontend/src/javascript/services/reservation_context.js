'use strict';

Application.Services.factory('ReservationContext', ['$resource', function ($resource) {
  return $resource('/api/reservation_contexts/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      },
      applicableOnValues: {
        method: 'GET',
        url: '/api/reservation_contexts/applicable_on_values',
        isArray: true
      }
    }
  );
}]);

'use strict';

Application.Services.factory('ICalendar', ['$resource', function ($resource) {
  return $resource('/api/i_calendar/:id',
    { id: '@id' }, {
      events: {
        method: 'GET',
        url: '/api/i_calendar/events'
      },
      sync: {
        method: 'POST',
        url: '/api/i_calendar/:id/sync',
        params: { id: '@id' }
      }
    }
  );
}]);

'use strict';

Application.Services.factory('Notification', ['$resource', function ($resource) {
  return $resource('/api/notifications/:id',
    { id: '@id' }, {
      query: {
        isArray: false
      },
      update: {
        method: 'PUT'
      },
      polling: {
        url: '/api/notifications/polling',
        method: 'GET'
      },
      last_unread: {
        url: '/api/notifications/last_unread',
        method: 'GET'
      }
    }
  );
}]);

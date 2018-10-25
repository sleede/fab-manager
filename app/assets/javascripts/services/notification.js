/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('Notification', ["$resource", $resource=>
  $resource("/api/notifications/:id",
    {id: "@id"}, {
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
  )

]);

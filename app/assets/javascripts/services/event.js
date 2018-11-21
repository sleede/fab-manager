/* eslint-disable
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('Event', ['$resource', $resource =>
  $resource('/api/events/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      },
      upcoming: {
        method: 'GET',
        url: '/api/events/upcoming/:limit',
        params: { limit: '@limit' },
        isArray: true
      }
    }
  )

]);

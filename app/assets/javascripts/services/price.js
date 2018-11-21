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

Application.Services.factory('Price', ['$resource', $resource =>
  $resource('/api/prices/:id',
    {}, {
      query: {
        isArray: true
      },
      update: {
        method: 'PUT'
      },
      compute: {
        method: 'POST',
        url: '/api/prices/compute',
        isArray: false
      }
    }
  )

]);

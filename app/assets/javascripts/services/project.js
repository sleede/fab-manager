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

Application.Services.factory('Project', ['$resource', $resource =>
  $resource('/api/projects/:id',
    { id: '@id' }, {
      lastPublished: {
        method: 'GET',
        url: '/api/projects/last_published',
        isArray: true
      },
      search: {
        method: 'GET',
        url: '/api/projects/search',
        isArray: false
      },
      allowedExtensions: {
        method: 'GET',
        url: '/api/projects/allowed_extensions',
        isArray: true
      }
    }
  )

]);

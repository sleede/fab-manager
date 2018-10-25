/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('OpenlabProject', ["$resource", $resource=>
  $resource("/api/openlab_projects/:id",
    {id: "@id"}, {
    query: {
      method: 'GET',
      isArray: false
    }
  }
  )

]);

/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('Theme', ["$resource", $resource=>
  $resource("/api/themes/:id",
    {id: "@id"}, {
    update: {
      method: 'PUT'
    }
  }
  )

]);

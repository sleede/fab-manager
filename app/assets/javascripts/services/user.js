/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('User', ["$resource", $resource=>
  $resource("/api/users",
    {}, {
    query: {
      isArray: false
    }
  }
  )

]);

/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('OpenAPIClient', ["$resource", $resource=>
  $resource("/api/open_api_clients/:id",
    {id: "@id"}, {
    resetToken: {
      method: 'PATCH',
      url: "/api/open_api_clients/:id/reset_token"
    },
    update: {
      method: 'PUT'
    }
  }
  )

]);

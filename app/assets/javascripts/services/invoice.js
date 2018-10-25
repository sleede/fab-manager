/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('Invoice', ["$resource", $resource=>
  $resource("/api/invoices/:id",
    {id: "@id"}, {
    update: {
      method: 'PUT'
    },
    list: {
      url: '/api/invoices/list',
      method: 'POST',
      isArray: true
    }
  }
  )

]);

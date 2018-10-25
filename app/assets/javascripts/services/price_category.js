/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('PriceCategory', ["$resource", $resource=>
  $resource("/api/price_categories/:id",
    {id: "@id"}, {
    update: {
      method: 'PUT'
    }
  }
  )

]);

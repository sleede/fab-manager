'use strict'

Application.Services.factory 'PriceCategory', ["$resource", ($resource)->
  $resource "/api/price_categories/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

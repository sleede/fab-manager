'use strict'

Application.Services.factory 'Pricing', ["$resource", ($resource)->
  $resource "/api/pricing",
    {},
    update:
      method: 'PUT'
]

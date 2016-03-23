'use strict'

Application.Services.factory 'Price', ["$resource", ($resource)->
  $resource "/api/prices/:id",
    {},
    query:
      isArray: false
    update:
      method: 'PUT'
    compute:
      method: 'POST'
      url: '/api/prices/compute'
      isArray: false
]

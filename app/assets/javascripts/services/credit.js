'use strict'

Application.Services.factory 'Credit', ["$resource", ($resource)->
  $resource "/api/credits/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

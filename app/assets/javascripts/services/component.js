'use strict'

Application.Services.factory 'Component', ["$resource", ($resource)->
  $resource "/api/components/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

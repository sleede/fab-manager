'use strict'

Application.Services.factory 'Machine', ["$resource", ($resource)->
  $resource "/api/machines/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

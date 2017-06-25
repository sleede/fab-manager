'use strict'

Application.Services.factory 'Space', ["$resource", ($resource)->
  $resource "/api/spaces/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

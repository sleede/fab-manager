'use strict'

Application.Services.factory 'Tag', ["$resource", ($resource)->
  $resource "/api/tags/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

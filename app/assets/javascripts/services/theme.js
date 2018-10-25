'use strict'

Application.Services.factory 'Theme', ["$resource", ($resource)->
  $resource "/api/themes/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

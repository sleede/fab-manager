'use strict'

Application.Services.factory 'Abuse', ["$resource", ($resource)->
  $resource "/api/abuses/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

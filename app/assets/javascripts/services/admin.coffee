'use strict'

Application.Services.factory 'Admin', ["$resource", ($resource)->
  $resource "/api/admins/:id",
    {id: "@id"},
    query:
      isArray: false
]

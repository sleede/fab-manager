'use strict'

Application.Services.factory 'Group', ["$resource", ($resource)->
  $resource "/api/groups/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

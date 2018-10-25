'use strict'

Application.Services.factory 'Plan', ["$resource", ($resource)->
  $resource "/api/plans/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

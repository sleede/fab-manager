'use strict'

Application.Services.factory 'OpenlabProject', ["$resource", ($resource)->
  $resource "/api/openlab_projects/:id",
    {id: "@id"},
    query:
      method: 'GET'
      isArray: false
]

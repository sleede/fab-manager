'use strict'

Application.Services.factory 'Training', ["$resource", ($resource)->
  $resource "/api/trainings/:id",
    {id: "@id"},
    update:
      method: 'PUT'
    availabilities:
      method: 'GET'
      url: "/api/trainings/:id/availabilities"
]

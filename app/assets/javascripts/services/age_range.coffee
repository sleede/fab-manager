'use strict'

Application.Services.factory 'AgeRange', ["$resource", ($resource)->
  $resource "/api/age_ranges/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

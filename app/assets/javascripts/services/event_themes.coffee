'use strict'

Application.Services.factory 'EventThemes', ["$resource", ($resource)->
  $resource "/api/event_themes/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

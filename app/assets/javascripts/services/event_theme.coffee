'use strict'

Application.Services.factory 'EventTheme', ["$resource", ($resource)->
  $resource "/api/event_themes/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

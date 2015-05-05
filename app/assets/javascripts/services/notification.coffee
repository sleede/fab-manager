'use strict'

Application.Services.factory 'Notification', ["$resource", ($resource)->
  $resource "/api/notifications/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

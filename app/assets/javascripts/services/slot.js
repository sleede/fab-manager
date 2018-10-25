'use strict'

Application.Services.factory 'Slot', ["$resource", ($resource)->
  $resource "/api/slots/:id",
    {id: "@id"},
    update:
      method: 'PUT'
    cancel:
      method: 'PUT'
      url: '/api/slots/:id/cancel'
]

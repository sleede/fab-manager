'use strict'

Application.Services.factory 'Reservation', ["$resource", ($resource)->
  $resource "/api/reservations/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

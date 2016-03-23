'use strict'

Application.Services.factory 'Subscription', ["$resource", ($resource)->
  $resource "/api/subscriptions/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

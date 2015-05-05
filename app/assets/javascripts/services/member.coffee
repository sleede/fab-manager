'use strict'

Application.Services.factory 'Member', ["$resource", ($resource)->
  $resource "/api/members/:id",
    {id: "@id"},
    lastSubscribed:
      method: 'GET'
      url: '/api/last_subscribed/:limit'
      params: {limit: "@limit"}
      isArray: true
]

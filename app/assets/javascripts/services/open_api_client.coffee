'use strict'

Application.Services.factory 'OpenAPIClient', ["$resource", ($resource)->
  $resource "/api/open_api_clients/:id",
    {id: "@id"},
    resetToken:
      method: 'PATCH'
      url: "/api/open_api_clients/:id/reset_token"
    update:
      method: 'PUT'
]

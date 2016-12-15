'use strict'

Application.Services.factory 'AuthProvider', ["$resource", ($resource)->
  $resource "/api/auth_providers/:id",
    {id: "@id"},
    update:
      method: 'PUT'
    mapping_fields:
      method: 'GET'
      url: '/api/auth_providers/mapping_fields'
    active:
      method: 'GET'
      url: '/api/auth_providers/active'
    send_code:
      method: 'POST'
      url: '/api/auth_providers/send_code'
]

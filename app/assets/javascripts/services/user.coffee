'use strict'

Application.Services.factory 'User', ["$resource", ($resource)->
  $resource "/api/users",
    {},
    query:
      isArray: false
]

'use strict'

Application.Services.factory 'Version', ["$resource", ($resource)->
  $resource "/api/version"
]

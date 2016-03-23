'use strict'

Application.Services.factory 'Statistics', ["$resource", ($resource)->
  $resource "/api/statistics"
]

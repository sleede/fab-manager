'use strict'

Application.Services.factory 'Export', ["$http", ($http)->
  status: (query) ->
    $http.post('/api/exports/status', query)
]

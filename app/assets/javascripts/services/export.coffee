'use strict'

Application.Services.factory 'Export', ["$http", ($http)->
  stats: (scope, query) ->
    $http.post('/stats/'+scope+'/export', query)
]

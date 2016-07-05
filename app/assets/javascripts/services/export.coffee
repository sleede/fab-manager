'use strict'

Application.Services.factory 'Export', ["$http", ($http)->
  stats: (scope, query) ->
    $http.post('/stats/'+scope+'/export', query).then((res) ->
      console.log(res)
    , (err) ->
      console.error(err)
    )

]

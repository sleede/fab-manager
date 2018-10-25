'use strict'

Application.Services.factory '_t', ["$filter", ($filter)->
  (key, interpolation = undefined, options = undefined) ->
    $filter('translate')(key, interpolation, options)
]

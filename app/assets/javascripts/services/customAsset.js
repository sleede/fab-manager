'use strict'

Application.Services.factory 'CustomAsset', ["$resource", ($resource)->
  $resource "/api/custom_assets/:name",
      {name: "@name"}
]

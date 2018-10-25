'use strict'

Application.Services.factory 'TrainingsPricing', ["$resource", ($resource)->
  $resource "/api/trainings_pricings/:id",
    {},
    update:
      method: 'PUT'
]

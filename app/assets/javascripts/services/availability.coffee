'use strict'

Application.Services.factory 'Availability', ["$resource", ($resource)->
  $resource "/api/availabilities/:id",
    {id: "@id"},
    machine:
      method: 'GET'
      url: '/api/availabilities/machines/:machineId'
      params: {machineId: "@machineId"}
      isArray: true
    reservations:
      method: 'GET'
      url: '/api/availabilities/:id/reservations'
      isArray: true
    trainings:
      method: 'GET'
      url: '/api/availabilities/trainings/:trainingId'
      params: {trainingId: "@trainingId"}
      isArray: true
    update:
      method: 'PUT'
]

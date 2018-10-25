'use strict'

Application.Services.factory 'Category', ["$resource", ($resource)->
  $resource "/api/categories/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

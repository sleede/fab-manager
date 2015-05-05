'use strict'

Application.Services.factory 'Licence', ["$resource", ($resource)->
  $resource "/api/licences/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

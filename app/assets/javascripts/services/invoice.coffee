'use strict'

Application.Services.factory 'Invoice', ["$resource", ($resource)->
  $resource "/api/invoices/:id",
    {id: "@id"},
    update:
      method: 'PUT'
]

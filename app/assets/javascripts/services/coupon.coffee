'use strict'

Application.Services.factory 'Coupon', ["$resource", ($resource)->
  $resource "/api/coupons/:id",
    {id: "@id"},
    update:
      method: 'PUT'
    validate:
      method: 'POST'
      url: '/api/coupons/validate'
    send:
      method: 'POST'
      url: '/api/coupons/send'
]

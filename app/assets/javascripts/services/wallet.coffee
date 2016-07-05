'use strict'

Application.Services.factory 'Wallet', ["$resource", ($resource)->
  $resource "/api/wallet",
    {},
    my:
      method: 'GET'
      url: '/api/wallet/my'
      isArray: false
    getWalletByUser:
      method: 'GET'
      url: '/api/wallet/by_user/:user_id'
      isArray: false
    transactions:
      method: 'GET'
      url: '/api/wallet/:id/transactions'
      isArray: true
]

'use strict'

Application.Services.factory 'helpers', [()->
    getAmountToPay: (price, walletAmount)->
      if walletAmount > price then 0 else price - walletAmount
  ]

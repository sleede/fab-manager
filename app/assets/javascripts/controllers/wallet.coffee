'use strict'

Application.Controllers.controller "WalletController", ['$scope', 'walletPromise', ($scope, walletPromise)->

  ### PUBLIC SCOPE ###

  ## current user wallet
  $scope.wallet = walletPromise
]

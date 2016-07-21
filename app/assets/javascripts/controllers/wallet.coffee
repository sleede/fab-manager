'use strict'

Application.Controllers.controller "WalletController", ['$scope', 'walletPromise', 'transactionsPromise', ($scope, walletPromise, transactionsPromise)->

  ### PUBLIC SCOPE ###

  ## current user wallet
  $scope.wallet = walletPromise

  ## current wallet transactions
  $scope.transactions = transactionsPromise
]

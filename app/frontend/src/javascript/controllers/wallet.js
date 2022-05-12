'use strict';

Application.Controllers.controller('WalletController', ['$scope', 'walletPromise', 'transactionsPromise', 'proofOfIdentityTypesPromise',
  function ($scope, walletPromise, transactionsPromise, proofOfIdentityTypesPromise) {
  /* PUBLIC SCOPE */

    // current user wallet
    $scope.wallet = walletPromise;

    // current wallet transactions
    $scope.transactions = transactionsPromise;

    $scope.hasProofOfIdentityTypes = proofOfIdentityTypesPromise.length > 0;
  }
]);

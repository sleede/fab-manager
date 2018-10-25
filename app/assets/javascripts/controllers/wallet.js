/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict'

Application.Controllers.controller('WalletController', ['$scope', 'walletPromise', 'transactionsPromise', function ($scope, walletPromise, transactionsPromise) {
  /* PUBLIC SCOPE */

  // # current user wallet
  $scope.wallet = walletPromise

  // # current wallet transactions
  return $scope.transactions = transactionsPromise
}
])

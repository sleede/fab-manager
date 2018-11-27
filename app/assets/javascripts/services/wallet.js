'use strict';

Application.Services.factory('Wallet', ['$resource', function ($resource) {
  return $resource('/api/wallet',
    {}, {
      getWalletByUser: {
        method: 'GET',
        url: '/api/wallet/by_user/:user_id',
        isArray: false
      },
      transactions: {
        method: 'GET',
        url: '/api/wallet/:id/transactions',
        isArray: true
      },
      credit: {
        method: 'PUT',
        url: '/api/wallet/:id/credit',
        isArray: false
      }
    }
  );
}]);

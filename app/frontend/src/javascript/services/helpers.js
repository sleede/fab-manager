'use strict';

Application.Services.factory('helpers', [function () {
  return ({
    getAmountToPay (price, walletAmount) {
      if (walletAmount > price) { return 0; } else { return price - walletAmount; }
    }
  });
}]);

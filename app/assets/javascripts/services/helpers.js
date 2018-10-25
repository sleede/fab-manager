/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('helpers', [()=>
    ({
        getAmountToPay(price, walletAmount){
          if (walletAmount > price) { return 0; } else { return price - walletAmount; }
      }
    })

  ]);

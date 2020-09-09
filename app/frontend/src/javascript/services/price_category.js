'use strict';

Application.Services.factory('PriceCategory', ['$resource', function ($resource) {
  return $resource('/api/price_categories/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

'use strict';

Application.Services.factory('Pricing', ['$resource', function ($resource) {
  return $resource('/api/pricing',
    {}, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

'use strict';

Application.Services.factory('Subscription', ['$resource', function ($resource) {
  return $resource('/api/subscriptions/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

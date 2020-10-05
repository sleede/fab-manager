'use strict';

Application.Services.factory('TrainingsPricing', ['$resource', function ($resource) {
  return $resource('/api/trainings_pricings/:id',
    {}, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

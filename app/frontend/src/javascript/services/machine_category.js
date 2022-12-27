'use strict';

Application.Services.factory('MachineCategory', ['$resource', function ($resource) {
  return $resource('/api/machine_categories/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

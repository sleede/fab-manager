'use strict';

Application.Services.factory('Export', ['$http', function ($http) {
  return ({
    status (query) {
      return $http.post('/api/exports/status', query);
    }
  });
}]);

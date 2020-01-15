Application.Services.factory('FabAnalytics', ['$resource', function ($resource) {
  return $resource('/api/analytics',
    {}, {
      data: {
        method: 'GET',
        url: '/api/analytics/data'
      }
    }
  );
}]);

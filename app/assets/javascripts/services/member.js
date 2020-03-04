'use strict';

Application.Services.factory('Member', ['$resource', '$q', function ($resource, $q) {
  return $resource('/api/members/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      },
      lastSubscribed: {
        method: 'GET',
        url: '/api/last_subscribed/:limit',
        params: { limit: '@limit' },
        isArray: true
      },
      merge: {
        method: 'PUT',
        url: '/api/members/:id/merge'
      },
      list: {
        url: '/api/members/list',
        method: 'POST',
        isArray: true
      },
      search: {
        method: 'GET',
        url: '/api/members/search/:query',
        params: { query: '@query' },
        isArray: true
      },
      mapping: {
        method: 'GET',
        url: '/api/members/mapping'
      },
      completeTour: {
        method: 'PATCH',
        url: '/api/members/:id/complete_tour',
        params: { id: '@id' },
        interceptor: {
          response: function (response) {
            if (Fablab.featureTourDisplay === 'session') {
              Fablab.sessionTours.push(response.data.tours[0]);
              return { tours: Fablab.sessionTours };
            }
            return response.data;
          }
        }
      }
    }
  );
}]);

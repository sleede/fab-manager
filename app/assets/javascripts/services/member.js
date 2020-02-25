'use strict';

Application.Services.factory('Member', ['$resource', function ($resource) {
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
        interceptor: function ($q) {
          return {
            request: function (config) {
              if (Fablab.featureTourDisplay === 'session') {
                throw new Error('session');
              }
              return config;
            },
            requestError: function (rejection) {
              // do something on error
              if (rejection.message === 'session') {
                return { toto: 1 };
              }
              return rejection;
            }
          };
        }
      }
    }
  );
}]);

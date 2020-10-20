'use strict';

Application.Services.factory('EventTheme', ['$resource', function ($resource) {
  return $resource('/api/event_themes/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

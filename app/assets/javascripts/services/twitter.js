'use strict';

Application.Services.factory('Twitter', ['$resource', function ($resource) {
  return $resource('/api/feeds/twitter_timelines');
}]);

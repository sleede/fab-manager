'use strict';

Application.Services.factory('CustomAsset', ['$resource', function ($resource) {
  return $resource('/api/custom_assets/:name',
    { name: '@name' });
}]);

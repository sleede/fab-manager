'use strict';

Application.Services.factory('PlanCategory', ['$resource', function ($resource) {
  return $resource('/api/plan_categories');
}]);

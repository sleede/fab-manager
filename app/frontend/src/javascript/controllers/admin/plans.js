/* eslint-disable
    camelcase,
    handle-callback-err,
    no-return-assign,
    no-undef,
    no-unused-expressions,
    no-unused-vars,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/**
 * Controller used in the plan creation form
 */
Application.Controllers.controller('NewPlanController', ['$scope', '$uibModal', 'groups', 'prices', 'partners', 'CSRF', '$state', 'growl', '_t', 'planCategories',
  function ($scope, $uibModal, groups, prices, partners, CSRF, $state, growl, _t, planCategories) {
    // protection against request forgery
    CSRF.setMetaTags();

    /**
     * Shows an error message forwarded from a child component
     */
    $scope.onError = function (message) {
      growl.error(message);
    };

    /**
     * Shows a success message forwarded from a child react components
     */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };
  }
]);

/**
 * Controller used in the plan edition form
 */
Application.Controllers.controller('EditPlanController', ['$scope', 'groups', 'plans', 'planPromise', 'machines', 'spaces', 'prices', 'partners', 'CSRF', '$state', '$transition$', 'growl', '$filter', '_t', 'Plan', 'planCategories',
  function ($scope, groups, plans, planPromise, machines, spaces, prices, partners, CSRF, $state, $transition$, growl, $filter, _t, Plan, planCategories) {
    // protection against request forgery
    CSRF.setMetaTags();

    $scope.suscriptionPlan = cleanPlan(planPromise);

    /**
     * Shows an error message forwarded from a child component
     */
    $scope.onError = function (message) {
      growl.error(message);
    };

    /**
     * Shows a success message forwarded from a child react components
     */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };

    // prepare the plan for the react-hook-form
    function cleanPlan (plan) {
      delete plan.$promise;
      delete plan.$resolved;
      return plan;
    }
  }
]);

/**
 * Controller used the plan-categories administration page.
 * This is just a wrapper to integrate the React component in the angular app
 */
Application.Controllers.controller('PlanCategoriesController', ['$scope', 'growl',
  function ($scope, growl) {
    /* PUBLIC SCOPE */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };

    $scope.onError = function (message) {
      growl.error(message);
    };
  }
]);

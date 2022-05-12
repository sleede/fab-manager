/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Controllers.controller('PlansIndexController', ['$scope', '$rootScope', '$state', '$uibModal', 'Auth', 'AuthService', 'dialogs', 'growl', 'Subscription', 'Member', 'subscriptionExplicationsPromise', '_t', 'Wallet', 'helpers', 'settingsPromise', 'Price',
  function ($scope, $rootScope, $state, $uibModal, Auth, AuthService, dialogs, growl, Subscription, Member, subscriptionExplicationsPromise, _t, Wallet, helpers, settingsPromise, Price) {
    /* PUBLIC SCOPE */

    // user to deal with
    $scope.ctrl = {
      member: null,
      member_id: null
    };

    // already subscribed plan of the current user
    $scope.paid =
        { plan: null };

    // plan to subscribe (shopping cart)
    $scope.selectedPlan = null;

    // the moment when the plan selection changed for the last time, used to trigger changes in the cart
    $scope.planSelectionTime = null;

    // the application global settings
    $scope.settings = settingsPromise;

    // Global config: is the user validation required ?
    $scope.enableUserValidationRequired = settingsPromise.user_validation_required === 'true';

    // Discount coupon to apply to the basket, if any
    $scope.coupon =
      { applied: null };

    // text that appears in the bottom-right box of the page (subscriptions rules details)
    $scope.subscriptionExplicationsAlert = subscriptionExplicationsPromise.setting.value;

    /**
     * Callback to deal with the subscription of the user selected in the dropdown list instead of the current user's
     * subscription. (admins and managers only)
     */
    $scope.updateMember = function () {
      $scope.selectedPlan = null;
      $scope.paid.plan = null;
      Member.get({ id: $scope.ctrl.member.id }, function (member) {
        $scope.ctrl.member = member;
      });
    };

    /**
     * Add the provided plan to the shopping basket
     * @param plan {Object} The plan to subscribe to
     */
    $scope.selectPlan = function (plan) {
      setTimeout(() => {
        if ($scope.isAuthenticated()) {
          if (!AuthService.isAuthorized(['admin', 'manager']) && (helpers.isUserValidationRequired($scope.settings, 'subscription') && !helpers.isUserValidated($scope.ctrl.member))) {
            return;
          }
          if ($scope.selectedPlan !== plan) {
            $scope.selectedPlan = plan;
            $scope.planSelectionTime = new Date();
          }
        } else {
          $scope.login();
        }
        $scope.$apply();
      }, 50);
    };

    $scope.canSelectPlan = function () {
      return helpers.isUserValidatedByType($scope.ctrl.member, $scope.settings, 'subscription');
    };

    /**
     * Open the modal dialog allowing the user to log into the system
     */
    $scope.userLogin = function () {
      setTimeout(() => {
        if (!$scope.isAuthenticated()) {
          $scope.login();
          $scope.$apply();
        }
      }, 50);
    };

    /**
     * Callback triggered when an error is raised on a lower-level component
     * @param message {string}
     */
    $scope.onError = function (message) {
      growl.error(message);
    };

    /**
     * Test if the provided date is in the future
     * @param dateTime {Date}
     * @return {boolean}
     */
    $scope.isInFuture = function (dateTime) {
      return (moment().diff(moment(dateTime)) < 0);
    };

    /**
     * To use as callback in Array.prototype.filter to get only enabled plans
     */
    $scope.filterDisabledPlans = function (plan) { return !plan.disabled; };

    /**
     * Once the subscription has been confirmed (payment process successfully completed), mark the plan as subscribed,
     * and update the user's subscription
     */
    $scope.afterPayment = function () {
      $scope.ctrl.member.subscribed_plan = angular.copy($scope.selectedPlan);
      if ($scope.ctrl.member.id === Auth._currentUser.id) {
        Auth._currentUser.subscribed_plan = angular.copy($scope.selectedPlan);
      }
      $scope.paid.plan = angular.copy($scope.selectedPlan);
      $scope.selectedPlan = null;
      $scope.coupon.applied = null;
    };

    /**
     * Callback triggered when the user has successfully changed his group
     */
    $scope.onGroupUpdateSuccess = function (message, user) {
      growl.success(message);
      setTimeout(() => {
        $scope.ctrl.member = _.cloneDeep(user);
        $scope.$apply();
      }, 50);
      if (AuthService.isAuthorized('member') ||
        (AuthService.isAuthorized('manager') && $scope.currentUser.id !== $scope.ctrl.member.id)) {
        $rootScope.currentUser.group_id = user.group_id;
        Auth._currentUser.group_id = user.group_id;
      }
    };

    /**
     * Check if it is allowed the change the group of the selected user
     */
    $scope.isAllowedChangingGroup = function () {
      return $scope.ctrl.member && !$scope.selectedPlan && !$scope.paid.plan;
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      if ($scope.currentUser) {
        if (!AuthService.isAuthorized('admin')) {
          $scope.ctrl.member = $scope.currentUser;
          $scope.paid.plan = $scope.currentUser.subscribed_plan;
        }
      }

      $scope.$on('devise:new-session', function (event, user) { if (user.role !== 'admin') { $scope.ctrl.member = user; } });
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

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

Application.Controllers.controller('PlansIndexController', ['$scope', '$rootScope', '$state', '$uibModal', 'Auth', 'AuthService', 'dialogs', 'growl', 'plansPromise', 'groupsPromise', 'Subscription', 'Member', 'subscriptionExplicationsPromise', '_t', 'Wallet', 'helpers', 'settingsPromise', 'Price',
  function ($scope, $rootScope, $state, $uibModal, Auth, AuthService, dialogs, growl, plansPromise, groupsPromise, Subscription, Member, subscriptionExplicationsPromise, _t, Wallet, helpers, settingsPromise, Price) {
    /* PUBLIC SCOPE */

    // list of groups
    $scope.groups = groupsPromise.filter(function (g) { return (g.slug !== 'admins') & !g.disabled; });

    // default : do not show the group changing form
    // group ID of the current/selected user
    $scope.group = {
      change: false,
      id: null
    };

    // list of plans, classified by group
    $scope.plansClassifiedByGroup = [];

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
      $scope.group.change = false;
      Member.get({ id: $scope.ctrl.member.id }, function (member) {
        $scope.ctrl.member = member;
        $scope.group.id = $scope.ctrl.member.group_id;
      });
    };

    /**
     * Add the provided plan to the shopping basket
     * @param plan {Object} The plan to subscribe to
     */
    $scope.selectPlan = function (plan) {
      setTimeout(() => {
        if ($scope.isAuthenticated()) {
          if ($scope.selectedPlan !== plan) {
            $scope.selectedPlan = plan;
            $scope.planSelectionTime = new Date();
          } else {
            $scope.selectedPlan = null;
          }
        } else {
          $scope.login();
        }
        $scope.$apply();
      }, 50);
    };

    /**
     * Check if the provided plan is currently selected
     * @param plan {Object} Resource plan
     */
    $scope.isSelected = function (plan) {
      return $scope.selectedPlan === plan;
    };

    /**
     * Return the group object, identified by the ID set in $scope.group.id
     */
    $scope.getUserGroup = function () {
      for (const group of Array.from($scope.groups)) {
        if (group.id === $scope.group.id) {
          return group;
        }
      }
    };

    /**
     * Change the group of the current/selected user to the one set in $scope.group.id
     */
    $scope.selectGroup = function () {
      Member.update({ id: $scope.ctrl.member.id }, { user: { group_id: $scope.group.id } }, function (user) {
        $scope.ctrl.member = user;
        $scope.group.change = false;
        $scope.selectedPlan = null;
        if (AuthService.isAuthorized('member') ||
          (AuthService.isAuthorized('manager') && $scope.currentUser.id !== $scope.ctrl.member.id)) {
          $rootScope.currentUser = user;
          Auth._currentUser.group_id = user.group_id;
          growl.success(_t('app.public.plans.your_group_was_successfully_changed'));
        } else {
          growl.success(_t('app.public.plans.the_user_s_group_was_successfully_changed'));
        }
      }
      , function (err) {
        if (AuthService.isAuthorized('member') ||
          (AuthService.isAuthorized('manager') && $scope.currentUser.id !== $scope.ctrl.member.id)) {
          growl.error(_t('app.public.plans.an_error_prevented_your_group_from_being_changed'));
        } else {
          growl.error(_t('app.public.plans.an_error_prevented_to_change_the_user_s_group'));
        }
        console.error(err);
      });
    };

    /**
     * Return an enumerable meaninful string for the gender of the provider user
     * @param user {Object} Database user record
     * @return {string} 'male' or 'female'
     */
    $scope.getGender = function (user) {
      if (user && user.statistic_profile) {
        if (user.statistic_profile.gender === 'true') { return 'male'; } else { return 'female'; }
      } else { return 'other'; }
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
     * Once the subscription is confirmed (payment process successfully completed), make the plan as subscribed,
     * and update the user's subscription
     */
    $scope.afterPayment = function () {
      $scope.ctrl.member.subscribed_plan = angular.copy($scope.selectedPlan);
      Auth._currentUser.subscribed_plan = angular.copy($scope.selectedPlan);
      $scope.paid.plan = angular.copy($scope.selectedPlan);
      $scope.selectedPlan = null;
      $scope.coupon.applied = null;
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // group all plans by Group
      for (const group of $scope.groups) {
        const groupObj = { id: group.id, name: group.name, plans: [], actives: 0 };
        for (const plan of plansPromise) {
          if (plan.group_id === group.id) {
            groupObj.plans.push(plan);
            if (!plan.disabled) { groupObj.actives++; }
          }
        }
        $scope.plansClassifiedByGroup.push(groupObj);
      }

      if ($scope.currentUser) {
        if (!AuthService.isAuthorized('admin')) {
          $scope.ctrl.member = $scope.currentUser;
          $scope.paid.plan = $scope.currentUser.subscribed_plan;
          $scope.group.id = $scope.currentUser.group_id;
        }
      }

      $scope.$on('devise:new-session', function (event, user) { if (user.role !== 'admin') { $scope.ctrl.member = user; } });
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

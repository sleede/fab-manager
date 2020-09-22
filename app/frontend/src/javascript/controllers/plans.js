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

Application.Controllers.controller('PlansIndexController', ['$scope', '$rootScope', '$state', '$uibModal', 'Auth', 'AuthService', 'dialogs', 'growl', 'plansPromise', 'groupsPromise', 'Subscription', 'Member', 'subscriptionExplicationsPromise', '_t', 'Wallet', 'helpers', 'settingsPromise',
  function ($scope, $rootScope, $state, $uibModal, Auth, AuthService, dialogs, growl, plansPromise, groupsPromise, Subscription, Member, subscriptionExplicationsPromise, _t, Wallet, helpers, settingsPromise) {
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

    // Discount coupon to apply to the basket, if any
    $scope.coupon =
      { applied: null };

    // Storage for the total price (plan price + coupon, if any)
    $scope.cart =
      { total: null };

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
      if ($scope.isAuthenticated()) {
        if ($scope.selectedPlan !== plan) {
          $scope.selectedPlan = plan;
          updateCartPrice();
        } else {
          $scope.selectedPlan = null;
        }
      } else {
        $scope.login();
      }
    };

    /**
     * Callback to trigger the payment process of the subscription
     */
    $scope.openSubscribePlanModal = function () {
      Wallet.getWalletByUser({ user_id: $scope.ctrl.member.id }, function (wallet) {
        const amountToPay = helpers.getAmountToPay($scope.cart.total, wallet.amount);
        if ((AuthService.isAuthorized('member') && amountToPay > 0)
          || (AuthService.isAuthorized('manager') && $scope.ctrl.member.id === $rootScope.currentUser.id && amountToPay > 0)) {
          if (settingsPromise.online_payment_module !== 'true') {
            growl.error(_t('app.public.plans.online_payment_disabled'));
          } else {
            return payByStripe();
          }
        } else {
          if (AuthService.isAuthorized('admin')
            || (AuthService.isAuthorized('manager') && $scope.ctrl.member.id !== $rootScope.currentUser.id)
            || amountToPay === 0) {
            return payOnSite();
          }
        }
      });
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

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // group all plans by Group
      for (const group of $scope.groups) {
        const groupObj = { id: group.id, name: group.name, plans: [], actives: 0 };
        for (let plan of plansPromise) {
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

      // watch when a coupon is applied to re-compute the total price
      $scope.$watch('coupon.applied', function (newValue, oldValue) {
        if ((newValue !== null) || (oldValue !== null)) {
          return updateCartPrice();
        }
      });
    };

    /**
     * Compute the total amount for the current reservation according to the previously set parameters
     * and assign the result in $scope.reserve.amountTotal
     */
    const updateCartPrice = function () {
      // first we check the selection of a user
      if (Object.keys($scope.ctrl.member).length > 0 && $scope.selectedPlan) {
        $scope.cart.total = $scope.selectedPlan.amount;
        // apply the coupon if any
        if ($scope.coupon.applied) {
          let discount;
          if ($scope.coupon.applied.type === 'percent_off') {
            discount = ($scope.cart.total * $scope.coupon.applied.percent_off) / 100;
          } else if ($scope.coupon.applied.type === 'amount_off') {
            discount = $scope.coupon.applied.amount_off;
          }
          return $scope.cart.total -= discount;
        }
      } else {
        return $scope.reserve.amountTotal = null;
      }
    };

    /**
     * Open a modal window which trigger the stripe payment process
     */
    const payByStripe = function () {
      $uibModal.open({
        templateUrl: '../../../templates/stripe/payment_modal.html',
        size: 'md',
        resolve: {
          selectedPlan () { return $scope.selectedPlan; },
          member () { return $scope.ctrl.member; },
          price () { return $scope.cart.total; },
          wallet () {
            return Wallet.getWalletByUser({ user_id: $scope.ctrl.member.id }).$promise;
          },
          coupon () { return $scope.coupon.applied; },
          stripeKey: ['Setting', function (Setting) { return Setting.get({ name: 'stripe_public_key' }).$promise; }]
        },
        controller: ['$scope', '$uibModalInstance', '$state', 'selectedPlan', 'member', 'price', 'Subscription', 'CustomAsset', 'wallet', 'helpers', '$filter', 'coupon', 'stripeKey',
          function ($scope, $uibModalInstance, $state, selectedPlan, member, price, Subscription, CustomAsset, wallet, helpers, $filter, coupon, stripeKey) {
            // User's wallet amount
            $scope.walletAmount = wallet.amount;

            // Final price to pay by the user
            $scope.amount = helpers.getAmountToPay(price, wallet.amount);

            // The plan that the user is about to subscribe
            $scope.selectedPlan = selectedPlan;

            // Used in wallet info template to interpolate some translations
            $scope.numberFilter = $filter('number');

            // Cart items
            $scope.cartItems = {
              coupon_code: ((coupon ? coupon.code : undefined)),
              subscription: {
                plan_id: selectedPlan.id
              }
            };

            // stripe publishable key
            $scope.stripeKey = stripeKey.setting.value;

            // retrieve the CGV
            CustomAsset.get({ name: 'cgv-file' }, function (cgv) { $scope.cgv = cgv.custom_asset; });

            /**
             * Callback for a click on the 'proceed' button.
             * Handle the stripe's card tokenization process response and save the subscription to the API with the
             * card token just created.
             */
            $scope.onPaymentSuccess = function (response) {
              $uibModalInstance.close(response);
            };
          }
        ]
      }).result['finally'](null).then(function (subscription) {
        $scope.ctrl.member.subscribed_plan = angular.copy($scope.selectedPlan);
        Auth._currentUser.subscribed_plan = angular.copy($scope.selectedPlan);
        $scope.paid.plan = angular.copy($scope.selectedPlan);
        $scope.selectedPlan = null;
        $scope.coupon.applied = null;
      });
    };

    /**
     * Open a modal window which trigger the local payment process
     */
    const payOnSite = function () {
      $uibModal.open({
        templateUrl: '../../../templates/plans/payment_modal.html',
        size: 'sm',
        resolve: {
          selectedPlan () { return $scope.selectedPlan; },
          member () { return $scope.ctrl.member; },
          price () { return $scope.cart.total; },
          wallet () {
            return Wallet.getWalletByUser({ user_id: $scope.ctrl.member.id }).$promise;
          },
          coupon () { return $scope.coupon.applied; }
        },
        controller: ['$scope', '$uibModalInstance', '$state', 'selectedPlan', 'member', 'price', 'Subscription', 'wallet', 'helpers', '$filter', 'coupon',
          function ($scope, $uibModalInstance, $state, selectedPlan, member, price, Subscription, wallet, helpers, $filter, coupon) {
            // user wallet amount
            $scope.walletAmount = wallet.amount;

            // subscription price, coupon subtracted if any
            $scope.price = price;

            // price to pay
            $scope.amount = helpers.getAmountToPay($scope.price, wallet.amount);

            // Used in wallet info template to interpolate some translations
            $scope.numberFilter = $filter('number');

            // The plan that the user is about to subscribe
            $scope.plan = selectedPlan;

            // The member who is subscribing a plan
            $scope.member = member;

            // Button label
            if ($scope.amount > 0) {
              $scope.validButtonName = _t('app.public.plans.confirm_payment_of_html', { ROLE: $scope.currentUser.role, AMOUNT: $filter('currency')($scope.amount) });
            } else {
              if ((price.price > 0) && ($scope.walletAmount === 0)) {
                $scope.validButtonName = _t('app.public.plans.confirm_payment_of_html', { ROLE: $scope.currentUser.role, AMOUNT: $filter('currency')(price.price) });
              } else {
                $scope.validButtonName = _t('app.shared.buttons.confirm');
              }
            }

            /**
             * Callback for the 'proceed' button.
             * Save the subscription to the API
             */
            $scope.ok = function () {
              $scope.attempting = true;
              Subscription.save({
                coupon_code: ((coupon ? coupon.code : undefined)),
                subscription: {
                  plan_id: selectedPlan.id,
                  user_id: member.id
                }
              }
              , function (data) { // success
                $uibModalInstance.close(data);
              }
              , function (data, status) { // failed
                $scope.alerts = [];
                $scope.alerts.push({ msg: _t('app.public.plans.an_error_occured_during_the_payment_process_please_try_again_later'), type: 'danger' });
                $scope.attempting = false;
              }
              );
            };

            /**
             * Callback for the 'cancel' button.
             * Close the modal box.
             */
            $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
          }
        ]
      }).result['finally'](null).then(function (subscription) {
        $scope.ctrl.member.subscribed_plan = angular.copy($scope.selectedPlan);
        Auth._currentUser.subscribed_plan = angular.copy($scope.selectedPlan);
        $scope.ctrl.member = null;
        $scope.paid.plan = angular.copy($scope.selectedPlan);
        $scope.selectedPlan = null;
        return $scope.coupon.applied = null;
      });
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

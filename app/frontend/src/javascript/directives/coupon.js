/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
Application.Directives.directive('coupon', [ '$rootScope', 'Coupon', '_t', function ($rootScope, Coupon, _t) {
  return ({
    restrict: 'E',
    scope: {
      show: '=',
      coupon: '=',
      total: '=',
      userId: '@'
    },
    templateUrl: '/shared/_coupon.html',
    link ($scope, element, attributes) {
      // Whether code input is shown or not (ie. the link 'I have a coupon' is shown)
      $scope.code =
          { input: false };

      // Available status are: 'pending', 'valid', 'invalid'
      $scope.status = 'pending';

      // Binding for the code inputed (see the attached template)
      $scope.couponCode = null;

      // Code validation messages
      $scope.messages = [];

      // Re-compute if the code can be applied when the total of the cart changes
      $scope.$watch('total', function (newValue, oldValue) {
        if (newValue && (newValue !== oldValue) && $scope.couponCode) {
          return $scope.validateCode();
        }
      });

      /**
       * Callback to validate the code
       */
      $scope.validateCode = function () {
        $scope.messages = [];
        if ($scope.couponCode === '') {
          $scope.status = 'pending';
          return $scope.coupon = null;
        } else {
          return Coupon.validate({ code: $scope.couponCode, user_id: $scope.userId, amount: $scope.total }, function (res) {
            $scope.status = 'valid';
            $scope.coupon = res;
            if (res.type === 'percent_off') {
              return $scope.messages.push({ type: 'success', message: _t('app.shared.coupon_input.the_coupon_has_been_applied_you_get_PERCENT_discount', { PERCENT: res.percent_off }) });
            } else {
              return $scope.messages.push({ type: 'success', message: _t('app.shared.coupon_input.the_coupon_has_been_applied_you_get_AMOUNT_CURRENCY', { AMOUNT: res.amount_off, CURRENCY: $rootScope.currencySymbol }) });
            }
          }
          , function (err) {
            $scope.status = 'invalid';
            $scope.coupon = null;
            return $scope.messages.push({ type: 'danger', message: _t(`app.shared.coupon_input.unable_to_apply_the_coupon_because_${err.data.status}`) });
          });
        }
      };

      /**
       * Callback to remove the message at provided index from the displayed list
       */
      $scope.closeMessage = function (index) { $scope.messages.splice(index, 1); };
    }
  });
}]);

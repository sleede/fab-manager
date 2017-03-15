Application.Directives.directive 'coupon', [ '$rootScope', 'Coupon', '_t', ($rootScope, Coupon, _t) ->
  {
    restrict: 'E'
    scope:
      show: '='
      coupon: '='
      total: '='
      userId: '@'
    templateUrl: '<%= asset_path "shared/_coupon.html" %>'
    link: ($scope, element, attributes) ->

      # Whether code input is shown or not (ie. the link 'I have a coupon' is shown)
      $scope.code =
          input: false

      # Available status are: 'pending', 'valid', 'invalid'
      $scope.status = 'pending'

      # Binding for the code inputed (see the attached template)
      $scope.couponCode = null

      # Code validation messages
      $scope.messages = []

      # Re-compute if the code can be applied when the total of the cart changes
      $scope.$watch 'total', (newValue, oldValue) ->
        if newValue and newValue != oldValue and $scope.couponCode
          $scope.validateCode()

      ##
      # Callback to validate the code
      ##
      $scope.validateCode = ->
        $scope.messages = []
        if $scope.couponCode == ''
          $scope.status = 'pending'
          $scope.coupon = null
        else
          Coupon.validate {code: $scope.couponCode, user_id: $scope.userId, amount: $scope.total}, (res) ->
            $scope.status = 'valid'
            $scope.coupon = res
            if res.type == 'percent_off'
              $scope.messages.push(type: 'success', message: _t('the_coupon_has_been_applied_you_get_PERCENT_discount', {PERCENT: res.percent_off}))
            else
              $scope.messages.push(type: 'success', message: _t('the_coupon_has_been_applied_you_get_AMOUNT_CURRENCY', {AMOUNT: res.amount_off, CURRENCY: $rootScope.currencySymbol}))
          , (err) ->
            $scope.status = 'invalid'
            $scope.coupon = null
            $scope.messages.push(type: 'danger', message: _t('unable_to_apply_the_coupon_because_'+err.data.status))

      ##
      # Callback to remove the message at provided index from the displayed list
      ##
      $scope.closeMessage = (index) ->
        $scope.messages.splice(index, 1);
  }
]



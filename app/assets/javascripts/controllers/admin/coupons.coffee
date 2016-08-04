
##
# Controller used in the coupon creation page
##
Application.Controllers.controller "NewCouponController", ["$scope", "$state",'Coupon', 'growl', '_t'
, ($scope, $state, Coupon, growl, _t) ->



  ### PUBLIC SCOPE ###

  ## Values for the coupon currently created
  $scope.coupon =
    active: true

  ## Default parameters for AngularUI-Bootstrap datepicker (used for coupon validity limit selection)
  $scope.datePicker =
    format: Fablab.uibDateFormat
    opened: false # default: datePicker is not shown
    options:
      startingDay: Fablab.weekStartingDay

  ##
  # Shows the validity limit datepicker
  # @param $event {Object} jQuery event object
  ##
  $scope.openDatePicker = ($event) ->
    $event.preventDefault()
    $event.stopPropagation()
    $scope.datePicker.opened = true

  ##
  # Callback to save the new coupon in $scope.coupon and redirect the user to the listing page
  ##
  $scope.saveCoupon = ->
    Coupon.save coupon: $scope.coupon, (coupon) ->
      $state.go('app.admin.pricing')
    , (err)->
      growl.error(_t('unable_to_create_the_coupon_an_error_occurred'))
      console.error(err)
]


##
# Controller used in the coupon edition page
##
Application.Controllers.controller "EditCouponController", ["$scope", 'Coupon', '_t'
, ($scope, Coupon, _t) ->



  ### PUBLIC SCOPE ###
  $scope.test = 'edit'
]
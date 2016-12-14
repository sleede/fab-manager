### COMMON CODE ###

# The validity per user defines how many time a user may ba able to use the same coupon
# Here are the various options for this parameter
userValidities = ['once', 'forever']


##
# Controller used in the coupon creation page
##
Application.Controllers.controller "NewCouponController", ["$scope", "$state", 'Coupon', 'growl', '_t'
, ($scope, $state, Coupon, growl, _t) ->

  ## Values for the coupon currently created
  $scope.coupon =
    active: true
    type: 'percent_off'

  ## Options for the validity per user
  $scope.validities = userValidities

  ## Default parameters for AngularUI-Bootstrap datepicker (used for coupon validity limit selection)
  $scope.datePicker =
    format: Fablab.uibDateFormat
    opened: false # default: datePicker is not shown
    minDate:  moment().toDate()
    options:
      startingDay: Fablab.weekStartingDay



  ##
  # Shows/hides the validity limit datepicker
  # @param $event {Object} jQuery event object
  ##
  $scope.toggleDatePicker = ($event) ->
    $event.preventDefault()
    $event.stopPropagation()
    $scope.datePicker.opened = !$scope.datePicker.opened



  ##
  # Callback to save the new coupon in $scope.coupon and redirect the user to the listing page
  ##
  $scope.saveCoupon = ->
    Coupon.save coupon: $scope.coupon, (coupon) ->
      $state.go('app.admin.pricing')
    , (err)->
      growl.error(_t('unable_to_create_the_coupon_check_code_already_used'))
      console.error(err)
]





##
# Controller used in the coupon edition page
##
Application.Controllers.controller "EditCouponController", ["$scope", "$state",  'Coupon', 'couponPromise', '_t', 'growl'
, ($scope, $state, Coupon, couponPromise, _t, growl) ->

  ### PUBLIC SCOPE ###


  ## Used in the form to freeze unmodifiable fields
  $scope.mode = 'EDIT'

  ## Coupon to edit
  $scope.coupon = couponPromise

  ## Options for the validity per user
  $scope.validities = userValidities

  ## Mapping for validation errors
  $scope.errors = {}

  ## Default parameters for AngularUI-Bootstrap datepicker (used for coupon validity limit selection)
  $scope.datePicker =
    format: Fablab.uibDateFormat
    opened: false # default: datePicker is not shown
    minDate:  moment().toDate()
    options:
      startingDay: Fablab.weekStartingDay



  ##
  # Shows/hides the validity limit datepicker
  # @param $event {Object} jQuery event object
  ##
  $scope.toggleDatePicker = ($event) ->
    $event.preventDefault()
    $event.stopPropagation()
    $scope.datePicker.opened = !$scope.datePicker.opened



  ##
  # Callback to save the coupon's changes to the API
  ##
  $scope.updateCoupon = ->
    $scope.errors = {}
    Coupon.update {id: $scope.coupon.id}, coupon: $scope.coupon, (coupon) ->
      $state.go('app.admin.pricing')
    , (err)->
      growl.error(_t('unable_to_update_the_coupon_an_error_occurred'))
      $scope.errors = err.data



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    # parse the date if any
    if (couponPromise.valid_until)
      $scope.coupon.valid_until = moment(couponPromise.valid_until).toDate()



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]
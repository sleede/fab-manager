'use strict'

##
# Controller used in the members listing page
##
Application.Controllers.controller "membersController", ["$scope", "$state", 'Member', ($scope, $state, Member) ->

  ## members list
  $scope.members = Member.query()

  ## Merbers ordering/sorting. Default: not sorted
  $scope.orderMember = null

  ##
  # Change the members ordering criterion to the one provided
  # @param orderBy {string} ordering criterion
  ##
  $scope.setOrderMember = (orderBy)->
    if $scope.orderMember == orderBy
      $scope.orderMember = '-'+orderBy
    else
      $scope.orderMember = orderBy
]



##
# Controller used when editing the current user's profile
##
Application.Controllers.controller "editProfileController", ["$scope", "$state", "Member", "Auth", 'growl', 'dialogs', 'CSRF', ($scope, $state, Member, Auth, growl, dialogs, CSRF) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/members/" + $scope.currentUser.id

  ## Form action on the above URL
  $scope.method = 'patch'

  ## Current user's profile
  $scope.user = Member.get {id: $scope.currentUser.id}

  ## Angular-Bootstrap datepicker configuration for birthday
  $scope.datePicker =
    format: 'dd/MM/yyyy'
    opened: false # default: datePicker is not shown
    options:
      startingDay: 1 # France: the week starts on monday



  ##
  # Callback to diplay the datepicker as a dropdown when clicking on the input field
  # @param $event {Object} jQuery event object
  ##
  $scope.openDatePicker = ($event) ->
    $event.preventDefault()
    $event.stopPropagation()
    $scope.datePicker.opened = true



  ##
  # For use with ngUpload (https://github.com/twilson63/ngUpload).
  # Intended to be the callback when the upload is done: any raised error will be stacked in the
  # $scope.alerts array. If everything goes fine, the user's profile is updated and the user is
  # redirected to the home page
  # @param content {Object} JSON - The upload's result
  ##
  $scope.submited = (content) ->
    if !content.id?
      $scope.alerts = []
      angular.forEach content, (v, k)->
        angular.forEach v, (err)->
          $scope.alerts.push
            msg: k+': '+err,
            type: 'danger'
    else
      $scope.currentUser.profile.user_avatar = content.profile.user_avatar
      Auth._currentUser.profile.user_avatar = content.profile.user_avatar
      $scope.currentUser.name = content.name
      Auth._currentUser.name = content.name
      $scope.currentUser = content
      Auth._currentUser = content
      $state.go('app.public.home')



  ##
  # For use with 'ng-class', returns the CSS class name for the uploads previews.
  # The preview may show a placeholder or the content of the file depending on the upload state.
  # @param v {*} any attribute, will be tested for truthiness (see JS evaluation rules)
  ##
  $scope.fileinputClass = (v)->
    if v
      'fileinput-exists'
    else
      'fileinput-new'
]



##
# Controller used on the public user's profile page (seeing another user's profile)
##
Application.Controllers.controller "showProfileController", ["$scope", "$stateParams", 'Member', ($scope, $stateParams, Member) ->

  ## Selected user's profile (id from the current URL)
  $scope.user = Member.get {id: $stateParams.id}
]

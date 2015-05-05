'use strict'

### COMMON CODE ###

##
# Provides a set of common properties and methods to the $scope parameter. They are used
# in the various members' admin controllers.
#
# Provides :
#  - $scope.groups = [{Group}]
#  - $scope.datePicker = {}
#  - $scope.submited(content)
#  - $scope.cancel()
#  - $scope.fileinputClass(v)
#  - $scope.openDatePicker($event)
#
# Requires :
#  - $state (Ui-Router) [ 'app.admin.members' ]
##
class MembersController
  constructor: ($scope, $state, Group) ->

    ## Retrieve the profiles groups (eg. students ...)
    Group.query (groups) ->
      $scope.groups = groups
      $scope.user.group_id = $scope.groups[0].id

    ## Default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker =
      format: 'dd/MM/yyyy'
      opened: false # default: datePicker is not shown
      options:
        startingDay: 1 # France: the week starts on monday


    ##
    # Shows the birth day datepicker
    # @param $event {Object} jQuery event object
    ##
    $scope.openDatePicker = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $scope.datePicker.opened = true



    ##
    # For use with ngUpload (https://github.com/twilson63/ngUpload).
    # Intended to be the callback when an upload is done: any raised error will be stacked in the
    # $scope.alerts array. If everything goes fine, the user is redirected to the members listing page.
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
        $state.go('app.admin.members')



    ##
    # Changes the admin's view to the members list page
    ##
    $scope.cancel = ->
      $state.go('app.admin.members')



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



##
# Controller used in the member edition page
##
Application.Controllers.controller "editMemberController", ["$scope", "$state", "$stateParams", "Member", 'dialogs', 'growl', 'Group', 'CSRF', ($scope, $state, $stateParams, Member, dialogs, growl, Group, CSRF) ->
  CSRF.setMetaTags()


  ### PUBLIC SCOPE ###

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/members/" + $stateParams.id

  ## Form action on the above URL
  $scope.method = 'patch'

  ## The user to edit
  $scope.user = {}

  ## Profiles types (student/standard/...)
  $scope.groups = []



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    ## Retrieve the member's profile details
    Member.get {id: $stateParams.id}, (resp)->
      $scope.user = resp

    ## Using the MembersController
    new MembersController($scope, $state, Group)



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]



##
# Controller used in the member's creation page (admin view)
##
Application.Controllers.controller "newMemberController", ["$scope", "$state", "$stateParams", "Member", 'Group', 'CSRF', ($scope, $state, $stateParams, Member, Group, CSRF) ->
  CSRF.setMetaTags()

  ### PUBLIC SCOPE ###

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/members"

  ## Form action on the above URL
  $scope.method = 'post'

  ## Default member's profile parameters
  $scope.user =
    plan_interval: ''



  ## Using the MembersController
  new MembersController($scope, $state, Group)
]

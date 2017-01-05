
'use strict'

Application.Controllers.controller "CompleteProfileController", ["$scope", "$rootScope", "$state", "$window", "_t", "growl", "CSRF", "Auth", "Member", "settingsPromise", "activeProviderPromise", "groupsPromise", "cguFile", "memberPromise", "Session", "dialogs", "AuthProvider"
, ($scope, $rootScope, $state, $window, _t, growl, CSRF, Auth, Member, settingsPromise, activeProviderPromise, groupsPromise, cguFile, memberPromise, Session, dialogs, AuthProvider) ->



  ### PUBLIC SCOPE ###

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/members/" + memberPromise.id

  ## Form action on the above URL
  $scope.method = 'patch'

  ## genre of the application name (eg. "_le_ Fablab" or "_la_ Fabrique")
  $scope.nameGenre = settingsPromise.name_genre

  ## name of the current fablab application (eg. "Fablab de la Casemate")
  $scope.fablabName = settingsPromise.fablab_name

  ## information from the current SSO provider
  $scope.activeProvider = activeProviderPromise

  ## list of user's groups (student/standard/...)
  $scope.groups = groupsPromise

  ## current user, contains information retrieved from the SSO
  $scope.user = memberPromise

  ## disallow the user to change his password as he connect from SSO
  $scope.preventPassword = true

  ## mapping of fields to disable
  $scope.preventField = {}

  ## CGU
  $scope.cgu = cguFile.custom_asset

  ## Angular-Bootstrap datepicker configuration for birthday
  $scope.datePicker =
    format: Fablab.uibDateFormat
    opened: false # default: datePicker is not shown
    options:
      startingDay: Fablab.weekStartingDay



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
      $scope.user.profile.user_avatar = content.profile.user_avatar
      Auth._currentUser.profile.user_avatar = content.profile.user_avatar
      $scope.user.name = content.name
      Auth._currentUser.name = content.name
      $scope.user = content
      Auth._currentUser = content
      $rootScope.currentUser = content
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



  ##
  # Merge the current user into the account with the given auth_token
  ##
  $scope.registerAuthToken = ->
    Member.merge {id: $rootScope.currentUser.id}, {user: {auth_token: $scope.user.auth_token}}, (user) ->
      $scope.user = user
      Auth._currentUser = user
      $rootScope.currentUser = user
      $state.go('app.public.home')
    , (err) ->
      if err.data.error
        growl.error(err.data.error)
      else
        growl.error(_t('an_unexpected_error_occurred_check_your_authentication_code'))
        console.error(err)



  ##
  # Return the email given by the SSO provider, parsed if needed
  # @return {String} E-mail of the current user
  ##
  $scope.ssoEmail = ->
    email = memberPromise.email
    if email
      duplicate = email.match(/^<([^>]+)>.{20}-duplicate$/)
      if duplicate
        return duplicate[1]
    email



  ##
  # Test if the user's mail is marked as duplicate
  # @return {boolean}
  ##
  $scope.hasDuplicate = ->
    email = memberPromise.email
    if email
      return !(email.match(/^<([^>]+)>.{20}-duplicate$/) == null)



  ##
  # Ask for email confirmation and send the SSO merging token again
  # @param $event {Object} jQuery event object
  ##
  $scope.resendCode = (event) ->
    event.preventDefault()
    event.stopPropagation()
    dialogs.confirm
      templateUrl: '<%= asset_path "profile/resend_code_modal.html" %>'
      resolve:
        object: ->
          email: memberPromise.email
    , (email) ->
      # Request the server to send an auth-migration email to the current user
      AuthProvider.send_code {email: email}, (res) ->
        growl.info(_t('code_successfully_sent_again'))
      , (err) ->
        growl.error(err.data.error)



  ##
  # Disconnect and re-connect the user to the SSO to force the synchronisation of the profile's data
  ##
  $scope.syncProfile = ->
    Auth.logout().then (oldUser) ->
      Session.destroy()
      $rootScope.currentUser = null
      $rootScope.toCheckNotifications = false
      $scope.notifications =
        total: 0
        unread: 0
      $window.location.href = activeProviderPromise.link_to_sso_connect



  ### PRIVATE SCOPE ###



  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    CSRF.setMetaTags()

    # init the birth date to JS object
    $scope.user.profile.birthday = moment($scope.user.profile.birthday).toDate()

    # bind fields protection with sso fields
    angular.forEach activeProviderPromise.mapping, (map) ->
      $scope.preventField[map] = true




  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()

]

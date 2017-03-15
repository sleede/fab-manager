'use strict'

##
# Controller used in the members listing page
##
Application.Controllers.controller "MembersController", ["$scope", 'Member', 'membersPromise', ($scope, Member, membersPromise) ->


  ### PRIVATE STATIC CONSTANTS ###

  # number of invoices loaded each time we click on 'load more...'
  MEMBERS_PER_PAGE = 10



  ### PUBLIC SCOPE ###

  ## currently displayed page of members
  $scope.page = 1

  ## members list
  $scope.members = membersPromise

  # true when all members are loaded
  $scope.noMoreResults = false

  ##
  # Callback for the 'load more' button.
  # Will load the next results of the current search, if any
  ##
  $scope.showNextMembers = ->
    $scope.page += 1
    Member.query {
      requested_attributes:'[profile]',
      page: $scope.page,
      size: MEMBERS_PER_PAGE
    }, (members) ->
      $scope.members = $scope.members.concat(members)

      if (!members[0] || members[0].maxMembers <= $scope.members.length)
        $scope.noMoreResults = true


  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    if (!membersPromise[0] || membersPromise[0].maxMembers <= $scope.members.length)
      $scope.noMoreResults = true



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()

]



##
# Controller used when editing the current user's profile
##
Application.Controllers.controller "EditProfileController", ["$scope", "$rootScope", "$state", "$window", "Member", "Auth", "Session", "activeProviderPromise", 'growl', 'dialogs', 'CSRF', 'memberPromise', 'groups', '_t'
, ($scope, $rootScope, $state, $window, Member, Auth, Session, activeProviderPromise, growl, dialogs, CSRF, memberPromise, groups, _t) ->



  ### PUBLIC SCOPE ###

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/members/" + $scope.currentUser.id

  ## list of groups
  $scope.groups = groups

  ## Form action on the above URL
  $scope.method = 'patch'

  ## Current user's profile
  $scope.user = memberPromise

  ## default : do not show the group changing form
  $scope.group =
      change: false

  ## group ID of the current/selected user
  $scope.userGroup = memberPromise.group_id

  ## active authentication provider parameters
  $scope.activeProvider = activeProviderPromise

  ## allow the user to change his password except if he connect from an SSO
  $scope.preventPassword = false

  ## mapping of fields to disable
  $scope.preventField = {}

  ## Should the passord be modified?
  $scope.password =
    change: false

  ## Angular-Bootstrap datepicker configuration for birthday
  $scope.datePicker =
    format: Fablab.uibDateFormat
    opened: false # default: datePicker is not shown
    options:
      startingDay: Fablab.weekStartingDay



  ##
  # Return the group object, identified by the ID set in $scope.userGroup
  ##
  $scope.getUserGroup = ->
    for group in $scope.groups
      if group.id == $scope.userGroup
        return group



  ##
  # Change the group of the current user to the one set in $scope.userGroup
  ##
  $scope.selectGroup = ->
    Member.update {id: $scope.user.id}, {user: {group_id: $scope.userGroup}}, (user) ->
      $scope.user = user
      $rootScope.currentUser = user
      Auth._currentUser.group_id = user.group_id
      $scope.group.change = false
      growl.success(_t('your_group_has_been_successfully_changed'))
    , (err) ->
      growl.error(_t('an_unexpected_error_prevented_your_group_from_being_changed'))
      console.error(err)



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
      $rootScope.currentUser = content
      $state.go('app.public.home')



  ##
  # Ask for confirmation then delete the current user's account
  # @param user {Object} the current user (to delete)
  ##
  $scope.deleteUser = (user)->
    dialogs.confirm
      resolve:
        object: ->
          title: _t('confirmation_required')
          msg: _t('do_you_really_want_to_delete_your_account')+' '+_t('all_data_relative_to_your_projects_will_be_lost')
    , -> # cancel confirmed
      Member.remove { id: user.id }, ->
        Auth.logout().then ->
          $state.go('app.public.home')
          growl.success(_t('your_user_account_has_been_successfully_deleted_goodbye'))
      , (error)->
        console.log(error)
        growl.error(_t('an_error_occured_preventing_your_account_from_being_deleted'))



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
  # Check if the of the properties editable by the user are linked to the SSO
  # @return {boolean} true if some editable fields are mapped with the SSO, false otherwise
  ##
  $scope.hasSsoFields = ->
    # if check if keys > 1 because there's a minimum of 1 mapping (id <-> provider-uid)
    # so the user may want to edit his profile on the SSO if at least 2 mappings exists
    Object.keys($scope.preventField).length > 1


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
      $window.location.href = $scope.activeProvider.link_to_sso_connect


  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    CSRF.setMetaTags()

    # init the birth date to JS object
    $scope.user.profile.birthday = moment($scope.user.profile.birthday).toDate()

    if $scope.activeProvider.providable_type != 'DatabaseProvider'
      $scope.preventPassword = true
    # bind fields protection with sso fields
    angular.forEach activeProviderPromise.mapping, (map) ->
      $scope.preventField[map] = true




  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]



##
# Controller used on the public user's profile page (seeing another user's profile)
##
Application.Controllers.controller "ShowProfileController", ["$scope", 'memberPromise', 'SocialNetworks', ($scope, memberPromise, SocialNetworks) ->

  ## Selected user's information
  $scope.user = memberPromise # DEPENDENCY WITH NAVINUM GAMIFICATION PLUGIN !!!!

  ## List of social networks associated with this user and toggle 'show all' state
  $scope.social =
    showAllLinks: false
    networks: SocialNetworks


  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    $scope.social.networks = filterNetworks()

  ##
  # Filter social network or website that are associated with the profile of the user provided in promise
  # and return the filtered networks
  # @return {Array}
  ##
  filterNetworks = ->
    networks = [];
    for network in SocialNetworks
      if $scope.user.profile[network] && $scope.user.profile[network].length > 0
        networks.push(network);
    networks

  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()

]

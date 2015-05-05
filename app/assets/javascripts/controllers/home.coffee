'use strict'

Application.Controllers.controller "homeController", ['$scope', '$stateParams', 'Member', 'Twitter', 'Project', 'Event', ($scope, $stateParams, Member, Twitter, Project, Event) ->



  ### PRIVATE STATIC CONSTANTS ###

  # The 4 last users will be displayed on the home page
  LAST_MEMBERS_LIMIT = 4

  # Only the last tweet is shown
  LAST_TWEETS_LIMIT = 1

  # The 3 closest events are shown
  LAST_EVENTS_LIMIT = 3



  ### PUBLIC SCOPE ###

  ## The last registered members who confirmed their addresses
  $scope.last_members = []

  ## The last tweets from the Fablab official twitter account
  $scope.last_tweets = []

  ## The last projects published/documented on the plateform
  $scope.last_projects = []

  ## The closest upcoming events
  $scope.upcoming_events = []



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    # display the reset password dialog if the parameter was provided
    if $stateParams.reset_password_token
      $scope.$parent.editPassword($stateParams.reset_password_token)

    # initialize the homepage data
    Member.lastSubscribed {limit: LAST_MEMBERS_LIMIT}, (members) ->
      $scope.last_members = members
    Twitter.query {limit: LAST_TWEETS_LIMIT}, (tweets) ->
      $scope.last_tweets = tweets
    Project.lastPublished (projects) ->
      $scope.last_projects = projects
    Event.upcoming {limit: LAST_EVENTS_LIMIT}, (events) ->
      $scope.upcoming_events = events



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]

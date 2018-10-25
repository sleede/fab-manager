'use strict'

Application.Controllers.controller "DashboardController", ["$scope", 'memberPromise', 'SocialNetworks', ($scope, memberPromise, SocialNetworks) ->

  ## Current user's profile
  $scope.user = memberPromise

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

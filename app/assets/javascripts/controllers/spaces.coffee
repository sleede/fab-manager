
##
# Manages the transition when a user clicks on the reservation button.
# According to the status of user currently logged into the system, redirect him to the reservation page,
# or display a modal window asking him to login or to create an account.
# @param space {{id:number}} An object containg the id of the space to book,
#   the object will be completed before the fonction returns.
# @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
##
_reserveSpace = (space, e) ->
  _this = this
  e.preventDefault()
  e.stopPropagation()

  # if a user is authenticated ...
  if _this.$scope.isAuthenticated()
    _this.$state.go('app.logged.space_reserve', { id: space.id })
  # if the user is not logged, open the login modal window
  else
    _this.$scope.login()



##
# Controller used in the public listing page, allowing everyone to see the list of spaces
##
Application.Controllers.controller "SpacesController", ["$scope", "$state", 'spacesPromise', ($scope, $state, spacesPromise) ->

  ## Retrieve the list of machines
  $scope.spaces = spacesPromise

  ##
  # Redirect the user to the space details page
  ##
  $scope.showSpace = (space) ->
    $state.go('app.public.space_show', { id: space.slug })

  ##
  # Callback to book a reservation for the current machine
  ##
  $scope.reserveSpace = _reserveSpace.bind
    $scope: $scope
    $state: $state
]


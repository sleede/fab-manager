
### COMMON CODE ###

##
# Provides a set of common callback methods to the $scope parameter. These methods are used
# in the various spaces' admin controllers.
#
# Provides :
#  - $scope.submited(content)
#  - $scope.cancel()
#  - $scope.fileinputClass(v)
#  - $scope.addFile()
#  - $scope.deleteFile(file)
#
# Requires :
#  - $scope.space.space_files_attributes = []
#  - $state (Ui-Router) [ 'app.public.spaces_list' ]
##
class SpacesController
  constructor: ($scope, $state) ->
    ##
    # For use with ngUpload (https://github.com/twilson63/ngUpload).
    # Intended to be the callback when the upload is done: any raised error will be stacked in the
    # $scope.alerts array. If everything goes fine, the user is redirected to the spaces list.
    # @param content {Object} JSON - The upload's result
    ##
    $scope.submited = (content) ->
      if !content.id?
        $scope.alerts = []
        angular.forEach content, (v, k)->
          angular.forEach v, (err)->
            $scope.alerts.push
              msg: k+': '+err
              type: 'danger'
      else
        $state.go('app.public.spaces_list')

    ##
    # Changes the current user's view, redirecting him to the spaces list
    ##
    $scope.cancel = ->
      $state.go('app.public.spaces_list')

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
    # This will create a single new empty entry into the space attachements list.
    ##
    $scope.addFile = ->
      $scope.space.space_files_attributes.push {}

    ##
    # This will remove the given file from the space attachements list. If the file was previously uploaded
    # to the server, it will be marked for deletion on the server. Otherwise, it will be simply truncated from
    # the attachements array.
    # @param file {Object} the file to delete
    ##
    $scope.deleteFile = (file) ->
      index = $scope.space.space_files_attributes.indexOf(file)
      if file.id?
        file._destroy = true
      else
        $scope.space.space_files_attributes.splice(index, 1)

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

  ## Retrieve the list of spaces
  $scope.spaces = spacesPromise

  ##
  # Redirect the user to the space details page
  ##
  $scope.showSpace = (space) ->
    $state.go('app.public.space_show', { id: space.slug })

  ##
  # Callback to book a reservation for the current space
  ##
  $scope.reserveSpace = _reserveSpace.bind
    $scope: $scope
    $state: $state
]



##
# Controller used in the space creation page (admin)
##
Application.Controllers.controller "NewSpaceController", ["$scope", "$state", 'CSRF',($scope, $state, CSRF) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/spaces/"

  ## Form action on the above URL
  $scope.method = "post"

  ## default space parameters
  $scope.space =
    space_files_attributes: []

  ## Using the SpacesController
  new SpacesController($scope, $state)
]
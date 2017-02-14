
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
# Controller used in the public listing page, allowing everyone to see the list of spaces
##
Application.Controllers.controller 'SpacesController', ['$scope', '$state', 'spacesPromise', ($scope, $state, spacesPromise) ->

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
  $scope.reserveSpace = (space) ->
    $state.go('app.logged.space_reserve', { id: space.slug })
]



##
# Controller used in the space creation page (admin)
##
Application.Controllers.controller 'NewSpaceController', ['$scope', '$state', 'CSRF',($scope, $state, CSRF) ->
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

Application.Controllers.controller 'ShowSpaceController', ['$scope', '$state', 'spacePromise', '_t', 'dialogs', ($scope, $state, spacePromise, _t, dialogs) ->

  ## Details of the space witch id/slug is provided in the URL
  $scope.space = spacePromise

  ##
  # Callback to book a reservation for the current space
  # @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
  ##
  $scope.reserveSpace = (event) ->
    event.preventDefault()
    $state.go('app.logged.space_reserve', { id: $scope.space.slug })

  ##
  # Callback to book a reservation for the current space
  # @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
  ##
  $scope.deleteSpace = (event) ->
    event.preventDefault()
    # check the permissions
    if $scope.currentUser.role isnt 'admin'
      console.error _t('space_show.unauthorized_operation')
    else
      dialogs.confirm
        resolve:
          object: ->
            title: _t('space_show.confirmation_required')
            msg: _t('space_show.do_you_really_want_to_delete_this_space')
      , -> # deletion confirmed
        # delete the machine then redirect to the machines listing
        $scope.space.$delete ->
          $state.go('app.public.machines_list')
        , (error)->
          growl.warning(_t('space_show.the_space_cant_be_deleted_because_it_is_already_reserved_by_some_users'))
##
]
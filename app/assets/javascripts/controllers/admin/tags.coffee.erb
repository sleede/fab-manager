Application.Controllers.controller "TagsController", ["$scope", 'tagsPromise', 'Tag', 'growl', '_t', ($scope, tagsPromise, Tag, growl, _t) ->

  ## List of users's tags
  $scope.tags = tagsPromise



  ##
  # Removes the newly inserted but not saved tag / Cancel the current tag modification
  # @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
  # @param index {number} tag index in the $scope.tags array
  ##
  $scope.cancelTag = (rowform, index) ->
    if $scope.tags[index].id?
      rowform.$cancel()
    else
      $scope.tags.splice(index, 1)



  ##
  # Creates a new empty entry in the $scope.tags array
  ##
  $scope.addTag = ->
    $scope.inserted =
      name: ''
    $scope.tags.push($scope.inserted)



  ##
  # Saves a new tag / Update an existing tag to the server (form validation callback)
  # @param data {Object} tag name
  # @param [data] {number} tag id, in case of update
  ##
  $scope.saveTag = (data, id) ->
    if id?
      Tag.update {id: id}, { tag: data }, (response) ->
        growl.success(_t('changes_successfully_saved'))
      , (error) ->
        growl.error(_t('an_error_occurred_while_saving_changes'))
    else
      Tag.save { tag: data }, (resp)->
        growl.success(_t('new_tag_successfully_saved'))
        $scope.tags[$scope.tags.length-1].id = resp.id
      , (error) ->
        growl.error(_t('an_error_occurred_while_saving_the_new_tag'))
        $scope.tags.splice($scope.tags.length-1, 1)



  ##
  # Deletes the tag at the specified index
  # @param index {number} tag index in the $scope.tags array
  ##
  $scope.removeTag = (index) ->
    # TODO add confirmation : les utilisateurs seront déasociés
    Tag.delete { id: $scope.tags[index].id }, (resp) ->
      growl.success(_t('tag_successfully_deleted'))
      $scope.tags.splice(index, 1)
    , (error) ->
      growl.error(_t('an_error_occurred_and_the_tag_deletion_failed'))


]

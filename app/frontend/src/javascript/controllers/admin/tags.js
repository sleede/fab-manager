/* eslint-disable
    handle-callback-err,
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
Application.Controllers.controller('TagsController', ['$scope', 'tagsPromise', 'Tag', 'dialogs', 'growl', '_t', function ($scope, tagsPromise, Tag, dialogs, growl, _t) {
  // List of users's tags
  $scope.tags = tagsPromise;

  /**
   * Removes the newly inserted but not saved tag / Cancel the current tag modification
   * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
   * @param index {number} tag index in the $scope.tags array
   */
  $scope.cancelTag = function (rowform, index) {
    if ($scope.tags[index].id != null) {
      return rowform.$cancel();
    } else {
      return $scope.tags.splice(index, 1);
    }
  };

  /**
   * Creates a new empty entry in the $scope.tags array
   */
  $scope.addTag = function () {
    $scope.inserted =
      { name: '' };
    return $scope.tags.push($scope.inserted);
  };

  /**
   * Saves a new tag / Update an existing tag to the server (form validation callback)
   * @param data {Object} tag name
   * @param [data] {number} tag id, in case of update
   */
  $scope.saveTag = function (data, id) {
    if (id != null) {
      return Tag.update({ id }, { tag: data }, response => growl.success(_t('app.admin.members.tag_form.changes_successfully_saved'))
        , error => growl.error(_t('app.admin.members.tag_form.an_error_occurred_while_saving_changes')));
    } else {
      return Tag.save({ tag: data }, function (resp) {
        growl.success(_t('app.admin.members.tag_form.new_tag_successfully_saved'));
        return $scope.tags[$scope.tags.length - 1].id = resp.id;
      }
      , function (error) {
        growl.error(_t('app.admin.members.tag_form.an_error_occurred_while_saving_the_new_tag'));
        return $scope.tags.splice($scope.tags.length - 1, 1);
      });
    }
  };

  /**
   * Deletes the tag at the specified index
   * @param index {number} tag index in the $scope.tags array
   */
  $scope.removeTag = index =>
    dialogs.confirm({
      resolve: {
        object () {
          return {
            title: _t('app.admin.members.tag_form.confirmation_required'),
            msg: _t('app.admin.members.tag_form.confirm_delete_tag_html')
          };
        }
      }
    }
    , () => {
      Tag.delete({ id: $scope.tags[index].id }, function (resp) {
        growl.success(_t('app.admin.members.tag_form.tag_successfully_deleted'));
        return $scope.tags.splice(index, 1);
      }
      , error => growl.error(_t('app.admin.members.tag_form.an_error_occurred_and_the_tag_deletion_failed')));
    });
}

]);

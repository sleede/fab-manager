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
Application.Controllers.controller('GroupsController', ['$scope', 'groupsPromise', 'Group', 'growl', '_t', function ($scope, groupsPromise, Group, growl, _t) {
  // List of users groups
  $scope.groups = groupsPromise;

  // Default: we show only enabled groups
  $scope.groupFiltering = 'enabled';

  // Available options for filtering groups by status
  $scope.filterDisabled = [
    'enabled',
    'disabled',
    'all'
  ];

  /**
   * Removes the newly inserted but not saved group / Cancel the current group modification
   * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
   * @param index {number} group index in the $scope.groups array
   */
  $scope.cancelGroup = function (rowform, index) {
    if ($scope.groups[index].id != null) {
      return rowform.$cancel();
    } else {
      return $scope.groups.splice(index, 1);
    }
  };

  /**
   * Creates a new empty entry in the $scope.groups array
   */
  $scope.addGroup = function () {
    $scope.inserted =
      { name: '' };
    return $scope.groups.push($scope.inserted);
  };

  /**
   * Saves a new group / Update an existing group to the server (form validation callback)
   * @param data {Object} group name
   * @param [id] {number} group id, in case of update
   */
  $scope.saveGroup = function (data, id) {
    if (id != null) {
      return Group.update({ id }, { group: data }, response => growl.success(_t('group_form.changes_successfully_saved'))
        , error => growl.error(_t('group_form.an_error_occurred_while_saving_changes')));
    } else {
      return Group.save({ group: data }, function (resp) {
        growl.success(_t('group_form.new_group_successfully_saved'));
        return $scope.groups[$scope.groups.length - 1].id = resp.id;
      }
      , function (error) {
        growl.error(_t('.group_forman_error_occurred_when_saving_the_new_group'));
        return $scope.groups.splice($scope.groups.length - 1, 1);
      });
    }
  };

  /**
   * Deletes the group at the specified index
   * @param index {number} group index in the $scope.groups array
   */
  $scope.removeGroup = index =>
    Group.delete({ id: $scope.groups[index].id }, function (resp) {
      growl.success(_t('group_form.group_successfully_deleted'));
      return $scope.groups.splice(index, 1);
    }
    , error => growl.error(_t('group_form.unable_to_delete_group_because_some_users_and_or_groups_are_still_linked_to_it')));

  /**
   * Enable/disable the group at the specified index
   * @param index {number} group index in the $scope.groups array
   */
  return $scope.toggleDisableGroup = function (index) {
    const group = $scope.groups[index];
    if (!group.disabled && (group.users > 0)) {
      return growl.error(_t('group_form.unable_to_disable_group_with_users', { USERS: group.users }, 'messageformat'));
    } else {
      return Group.update({ id: group.id }, { group: { disabled: !group.disabled } }, function (response) {
        $scope.groups[index] = response;
        return growl.success(_t('group_form.group_successfully_enabled_disabled', { STATUS: response.disabled }, 'messageformat'));
      }
      , error => growl.error(_t('group_form.unable_to_enable_disable_group', { STATUS: !group.disabled }, 'messageformat')));
    }
  };
}

]);

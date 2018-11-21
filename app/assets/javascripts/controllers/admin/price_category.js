/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict'

/**
 * Controller used in price category creation/edition form dialog
 */
Application.Controllers.controller('PriceCategoryController', ['$scope', '$uibModalInstance', 'category',
  function ($scope, $uibModalInstance, category) {
    // Price category to edit/empty object for new category
    $scope.category = category

    /**
     * Callback for form validation
     */
    $scope.ok = () => $uibModalInstance.close($scope.category)

    /**
     * Do not validate the modifications, hide the modal
     */
    return $scope.cancel = () => $uibModalInstance.dismiss('cancel')
  }
])

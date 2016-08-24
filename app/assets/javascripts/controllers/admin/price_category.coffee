'use strict'

##
# Controller used in price category creation/edition form dialog
##
Application.Controllers.controller "PriceCategoryController", ["$scope", "$uibModalInstance", "category"
, ($scope, $uibModalInstance, category) ->

    ## Price category to edit/empty object for new category
    $scope.category = category

    ##
    # Callback for form validation
    ##
    $scope.ok = ->
      $uibModalInstance.close($scope.category)

    ##
    # Do not validate the modifications, hide the modal
    ##
    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')
]
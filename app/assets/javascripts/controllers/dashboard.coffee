'use strict'

Application.Controllers.controller "DashboardController", ["$scope", 'memberPromise', ($scope, memberPromise) ->

  ## Current user's profile
  $scope.user = memberPromise
]

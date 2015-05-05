'use strict'

##
# Controller used on the private projects listing page (my dashboard/projects)
##
Application.Controllers.controller "dashboardProjectsController", ["$scope", 'Member', ($scope, Member) ->

## Current user's profile
  $scope.user = Member.get {id: $scope.currentUser.id}
]



##
# Controller used on the personal trainings page (my dashboard/trainings)
##
Application.Controllers.controller "dashboardTrainingsController", ["$scope", 'Member', ($scope, Member) ->

## Current user's profile
  $scope.user = Member.get {id: $scope.currentUser.id}
]



##
# Controller used on the private events page (my dashboard/events)
##
Application.Controllers.controller "dashboardEventsController", ["$scope", 'Member', ($scope, Member) ->

## Current user's profile
  $scope.user = Member.get {id: $scope.currentUser.id}
]



##
# Controller used on the personal invoices listing page (my dashboard/invoices)
##
Application.Controllers.controller "dashboardInvoicesController", ["$scope", 'Member', ($scope, Member) ->

## Current user's profile
  $scope.user = Member.get {id: $scope.currentUser.id}
]

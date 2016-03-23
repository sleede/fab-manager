'use strict'

##
# Controller used in notifications page
# inherits $scope.$parent.notifications (unread notifications) from ApplicationController
##
Application.Controllers.controller "NotificationsController", ["$scope", 'Notification', ($scope, Notification) ->



  ### PRIVATE STATIC CONSTANTS ###

  # Number of notifications added to the page when the user clicks on 'load next notifications'
  NOTIFICATIONS_PER_PAGE = 15



  ### PUBLIC SCOPE ###

  ## Array containg the archived notifications (already read)
  $scope.notificationsRead = []

  ## By default, the pagination mode is activated to limit the page size
  $scope.paginateActive = true

  ## The currently displayed page number
  $scope.page = 1



  ##
  # Mark the provided notification as read, updating its status on the server and moving it
  # to the already read notifications list.
  # @param notification {{id:number}} the notification to mark as read
  # @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
  ##
  $scope.markAsRead = (notification, e) ->
    e.preventDefault()
    Notification.update {id: notification.id},
      id: notification.id
      is_read: true
    , ->
      index = $scope.$parent.notifications.indexOf(notification)
      $scope.$parent.notifications.splice(index,1)
      $scope.notificationsRead.push notification



  ##
  # Mark every unread notifications as read and move them for the unread list to to read array.
  ##
  $scope.markAllAsRead = ->
    Notification.update {}
    , -> # success
      angular.forEach $scope.$parent.notifications, (n)->
        $scope.notificationsRead.push n

      $scope.$parent.notifications.splice(0, $scope.$parent.notifications.length)



  ##
  # Request the server to retrieve the next undisplayed notifications and add them
  # to the archived notifications list.
  ##
  $scope.addMoreNotificationsReaded = ->
    Notification.query {is_read: true, page: $scope.page}, (notifications) ->
      $scope.notificationsRead = $scope.notificationsRead.concat notifications
      $scope.paginateActive = false if notifications.length < NOTIFICATIONS_PER_PAGE

    $scope.page += 1



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    $scope.addMoreNotificationsReaded()



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]

'use strict'

##
# Controller used in notifications page
# inherits $scope.$parent.notifications (global notifications state) from ApplicationController
##
Application.Controllers.controller "NotificationsController", ["$scope", 'Notification', ($scope, Notification) ->



  ### PRIVATE STATIC CONSTANTS ###

  # Number of notifications added to the page when the user clicks on 'load next notifications'
  NOTIFICATIONS_PER_PAGE = 15



  ### PUBLIC SCOPE ###

  ## Array containg the archived notifications (already read)
  $scope.notificationsRead = []

  ## Array containg the new notifications (not read)
  $scope.notificationsUnread = []

  ## Total number of notifications for the current user
  $scope.total = 0

  ## Total number of unread notifications for the current user
  $scope.totalUnread = 0

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
    , (updatedNotif) ->
      # remove notif from unreads
      index = $scope.notificationsUnread.indexOf(notification)
      $scope.notificationsUnread.splice(index,1)
      # add update notif to read
      $scope.notificationsRead.push updatedNotif
      # update counters
      $scope.$parent.notifications.unread -= 1
      $scope.totalUnread -= 1



  ##
  # Mark every unread notifications as read and move them for the unread list to to read array.
  ##
  $scope.markAllAsRead = ->
    Notification.update {}
    , -> # success
      # add notifs to read
      angular.forEach $scope.notificationsUnread, (n)->
        n.is_read = true
        $scope.notificationsRead.push n
      # clear unread
      $scope.notificationsUnread = []
      # update counters
      $scope.$parent.notifications.unread = 0
      $scope.totalUnread = 0



  ##
  # Request the server to retrieve the next notifications and add them
  # to their corresponding notifications list (read or unread).
  ##
  $scope.addMoreNotifications = ->
    Notification.query {page: $scope.page}, (notifications) ->
      $scope.total = notifications.totals.total
      $scope.totalUnread = notifications.totals.unread
      angular.forEach notifications.notifications, (notif) ->
        if notif.is_read
          $scope.notificationsRead.push(notif)
        else
          $scope.notificationsUnread.push(notif)
      $scope.paginateActive = (notifications.totals.total > ($scope.notificationsRead.length + $scope.notificationsUnread.length))

    $scope.page += 1



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    $scope.addMoreNotifications()



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]

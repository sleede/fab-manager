/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

//#
// Controller used in notifications page
// inherits $scope.$parent.notifications (global notifications state) from ApplicationController
//#
Application.Controllers.controller("NotificationsController", ["$scope", 'Notification', function($scope, Notification) {



  /* PRIVATE STATIC CONSTANTS */

  // Number of notifications added to the page when the user clicks on 'load next notifications'
  const NOTIFICATIONS_PER_PAGE = 15;



  /* PUBLIC SCOPE */

  //# Array containg the archived notifications (already read)
  $scope.notificationsRead = [];

  //# Array containg the new notifications (not read)
  $scope.notificationsUnread = [];

  //# Total number of notifications for the current user
  $scope.total = 0;

  //# Total number of unread notifications for the current user
  $scope.totalUnread = 0;

  //# By default, the pagination mode is activated to limit the page size
  $scope.paginateActive = true;

  //# The currently displayed page number
  $scope.page = 1;



  //#
  // Mark the provided notification as read, updating its status on the server and moving it
  // to the already read notifications list.
  // @param notification {{id:number}} the notification to mark as read
  // @param e {Object} see https://docs.angularjs.org/guide/expression#-event-
  //#
  $scope.markAsRead = function(notification, e) {
    e.preventDefault();
    return Notification.update({id: notification.id}, {
      id: notification.id,
      is_read: true
    }
    , function(updatedNotif) {
      // remove notif from unreads
      const index = $scope.notificationsUnread.indexOf(notification);
      $scope.notificationsUnread.splice(index,1);
      // add update notif to read
      $scope.notificationsRead.push(updatedNotif);
      // update counters
      $scope.$parent.notifications.unread -= 1;
      return $scope.totalUnread -= 1;
    });
  };



  //#
  // Mark every unread notifications as read and move them for the unread list to to read array.
  //#
  $scope.markAllAsRead = () =>
    Notification.update({}
    , function() { // success
      // add notifs to read
      angular.forEach($scope.notificationsUnread, function(n){
        n.is_read = true;
        return $scope.notificationsRead.push(n);
      });
      // clear unread
      $scope.notificationsUnread = [];
      // update counters
      $scope.$parent.notifications.unread = 0;
      return $scope.totalUnread = 0;
    })
  ;



  //#
  // Request the server to retrieve the next notifications and add them
  // to their corresponding notifications list (read or unread).
  //#
  $scope.addMoreNotifications = function() {
    Notification.query({page: $scope.page}, function(notifications) {
      $scope.total = notifications.totals.total;
      $scope.totalUnread = notifications.totals.unread;
      angular.forEach(notifications.notifications, function(notif) {
        if (notif.is_read) {
          return $scope.notificationsRead.push(notif);
        } else {
          return $scope.notificationsUnread.push(notif);
        }
      });
      return $scope.paginateActive = (notifications.totals.total > ($scope.notificationsRead.length + $scope.notificationsUnread.length));
    });

    return $scope.page += 1;
  };



  /* PRIVATE SCOPE */

  //#
  // Kind of constructor: these actions will be realized first when the controller is loaded
  //#
  const initialize = () => $scope.addMoreNotifications();



  //# !!! MUST BE CALLED AT THE END of the controller
  return initialize();
}
]);

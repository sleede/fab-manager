/* eslint-disable
    no-return-assign,
    no-undef,
    no-unused-vars,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/**
 * Controller used in notifications page
 */
Application.Controllers.controller('NotificationsController', ['$scope', 'growl', function ($scope, growl) {
  /* PUBLIC SCOPE */

  /**
 * Shows an error message forwarded from a child react component
 */
  $scope.onError = function (message) {
    growl.error(message);
  };
}
]);

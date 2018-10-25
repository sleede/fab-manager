/* eslint-disable
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
'use strict'

Application.Services.factory('AuthService', ['Session', function (Session) {
  return {
    isAuthenticated () {
      return (Session.currentUser != null) && (Session.currentUser.id != null)
    },

    isAuthorized (authorizedRoles) {
      if (!angular.isArray(authorizedRoles)) {
        authorizedRoles = [authorizedRoles]
      }

      return this.isAuthenticated() && (authorizedRoles.indexOf(Session.currentUser.role) !== -1)
    }
  }
}
])

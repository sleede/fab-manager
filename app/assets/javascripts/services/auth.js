'use strict';

Application.Services.factory('AuthService', ['Session', function (Session) {
  return {
    isAuthenticated () {
      return (Session.currentUser != null) && (Session.currentUser.id != null);
    },

    isAuthorized (authorizedRoles) {
      if (!angular.isArray(authorizedRoles)) {
        authorizedRoles = [authorizedRoles];
      }

      return this.isAuthenticated() && (authorizedRoles.indexOf(Session.currentUser.role) !== -1);
    }
  };
}]);

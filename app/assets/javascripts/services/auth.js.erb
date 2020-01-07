'use strict';

Application.Services.factory('AuthService', ['Session', 'CSRF', function (Session, CSRF) {
  let service = {};

  service.isAuthenticated = function() {
    return (Session.currentUser != null) && (Session.currentUser.id != null);
  };

  service.isAuthorized = function(authorizedRoles) {
    if (!angular.isArray(authorizedRoles)) {
      authorizedRoles = [authorizedRoles];
    }
    return service.isAuthenticated() && (authorizedRoles.indexOf(Session.currentUser.role) !== -1);
  };

  return service;
}]);

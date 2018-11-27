'use strict';

Application.Services.service('Session', [ function () {
  this.create = function (user) {
    return this.currentUser = user;
  };

  this.destroy = function () {
    return this.currentUser = null;
  };

  return this;
}]);

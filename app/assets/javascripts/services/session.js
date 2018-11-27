'use strict';

Application.Services.service('Session', [ function () {
  this.create = function (user) {
    this.currentUser = user;
  };

  this.destroy = function () {
    this.currentUser = null;
  };

  return this;
}]);

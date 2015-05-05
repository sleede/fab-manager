'use strict'

Application.Services.factory 'AuthService', ["Session", (Session) ->
    isAuthenticated: ->
      Session.currentUser? and Session.currentUser.id?

    isAuthorized: (authorizedRoles) ->
      if !angular.isArray(authorizedRoles)
        authorizedRoles = [authorizedRoles]

      @isAuthenticated() and authorizedRoles.indexOf(Session.currentUser.role) != -1
  ]

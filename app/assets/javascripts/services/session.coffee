'use strict'

Application.Services.service 'Session', [ ->
  @create = (user)->
    @currentUser = user

  @destroy = ->
    @currentUser = null

  return @
]

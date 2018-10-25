'use strict'

Application.Services.factory 'Twitter', ["$resource", ($resource)->
  $resource "/api/feeds/twitter_timelines"
]

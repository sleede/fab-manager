'use strict'

Application.Services.factory 'Member', ["$resource", ($resource)->
  $resource "/api/members/:id",
    {id: "@id"},
    update:
      method: 'PUT'
    lastSubscribed:
      method: 'GET'
      url: '/api/last_subscribed/:limit'
      params: {limit: "@limit"}
      isArray: true
    merge:
      method: 'PUT'
      url: '/api/members/:id/merge'
    list:
      url: '/api/members/list'
      method: 'POST'
      isArray: true
    search:
      method: 'GET'
      url: '/api/members/search/:query/:subscription'
      params: {query: "@query", subscription: "@subscription"}
      isArray: true
]

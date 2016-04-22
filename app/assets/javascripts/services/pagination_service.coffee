'use strict'

Application.Services.factory("paginationService", [->
  helpers = {}

  helpers.pageCount = (totalCount, perPage)->
    Math.ceil(totalCount/perPage)

  helpers.hasNextPage = (currentPage, totalCount, perPage)->
    _pageCount = helpers.pageCount(totalCount, perPage)
    (_pageCount != currentPage) and (_pageCount != 0)

  Instance = (resourceService, currentPage, perPage, totalCount, defaultQueryParams, callback, functionName)->
    @resourceService = resourceService
    @currentPage = currentPage
    @perPage = perPage
    @totalCount = totalCount
    @defaultQueryParams = defaultQueryParams
    @callback = callback
    @functionName = functionName || 'query'
    @loading = false

    @pageCount = ->
      helpers.pageCount(@totalCount, @perPage)

    @hasNextPage = ->
      helpers.hasNextPage(@currentPage, @totalCount, @perPage)

    @loadMore = (queryParams)->
      @currentPage += 1
      @loading = true

      _queryParams = { page: @currentPage, per_page: @perPage }

      if queryParams
        for k,v of queryParams
          _queryParams[k] = v

      for k,v of @defaultQueryParams
        _queryParams[k] = v

      @resourceService[@functionName](_queryParams, (dataPromise)=>
        @callback(dataPromise)
        @loading = false
      )

    return

  return { Instance: Instance }
])

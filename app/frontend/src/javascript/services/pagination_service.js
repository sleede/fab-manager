'use strict';

Application.Services.factory('paginationService', [function () {
  const helpers = {};

  helpers.pageCount = (totalCount, perPage) => Math.ceil(totalCount / perPage);

  helpers.hasNextPage = function (currentPage, totalCount, perPage) {
    const _pageCount = helpers.pageCount(totalCount, perPage);
    return (_pageCount !== currentPage) && (_pageCount !== 0);
  };

  const Instance = function (resourceService, currentPage, perPage, totalCount, defaultQueryParams, callback, functionName) {
    this.resourceService = resourceService;
    this.currentPage = currentPage;
    this.perPage = perPage;
    this.totalCount = totalCount;
    this.defaultQueryParams = defaultQueryParams;
    this.callback = callback;
    this.functionName = functionName || 'query';
    this.loading = false;

    this.pageCount = function () {
      return helpers.pageCount(this.totalCount, this.perPage);
    };

    this.hasNextPage = function () {
      return helpers.hasNextPage(this.currentPage, this.totalCount, this.perPage);
    };

    this.loadMore = function (queryParams) {
      let k, v;
      this.currentPage += 1;
      this.loading = true;

      const _queryParams = { page: this.currentPage, per_page: this.perPage };

      if (queryParams) {
        for (k in queryParams) {
          v = queryParams[k];
          _queryParams[k] = v;
        }
      }

      for (k in this.defaultQueryParams) {
        v = this.defaultQueryParams[k];
        _queryParams[k] = v;
      }

      this.resourceService[this.functionName](_queryParams, dataPromise => {
        this.callback(dataPromise);
        this.loading = false;
      });
    };
  };

  return { Instance };
}
]);

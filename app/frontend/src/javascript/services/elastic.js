// The statistics client only addresses authenticated Rails routes on this origin.
Application.Services.service('es', ['$http', '$q', function ($http, $q) {
  const families = ['account', 'event', 'machine', 'project', 'subscription', 'training', 'user', 'space', 'order'];
  const parameters = ['size', 'scroll', 'stat-type', 'custom-query', 'start-date', 'end-date'];
  const headers = { Accept: 'application/json' };

  const complete = function (promise, callback) {
    if (callback) promise.then(data => callback(null, data), error => callback(error));
    return promise;
  };

  this.search = function (options, callback) {
    if (options.index !== 'stats' || !families.includes(options.type)) {
      return complete($q.reject(new Error('Unknown statistics family')), callback);
    }
    const params = {};
    parameters.forEach(key => { if (options[key] !== undefined) params[key] = options[key]; });
    if (options.searchType !== undefined) params.search_type = options.searchType;
    return complete($http.post(`/stats/${options.type}/_search`, options.body, { params, headers }).then(response => response.data), callback);
  };

  this.scroll = function (options, callback) {
    return complete($http.post('/_search/scroll', { scroll: options.scroll, scrollId: options.body.scrollId }, { headers })
      .then(response => response.data), callback);
  };

  this.clearScroll = function (cursor) {
    return $http.delete('/_search/scroll', { data: { scrollId: cursor }, headers: { ...headers, 'Content-Type': 'application/json' } });
  };
}]);

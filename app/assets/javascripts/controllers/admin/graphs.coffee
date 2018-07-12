'use strict'

Application.Controllers.controller "GraphsController", ["$scope", "$state", "$rootScope",  'es', 'Statistics', '_t'
, ($scope, $state, $rootScope, es, Statistics, _t) ->



  ### PRIVATE STATIC CONSTANTS ###

  ## height of the HTML/SVG charts elements in pixels
  CHART_HEIGHT = 500

  ## Label of the charts' horizontal axes
  X_AXIS_LABEL = _t('date')

  ## Label of the charts' vertical axes
  Y_AXIS_LABEL = _t('number')

  ## Colors for the line charts. Each new line uses the next color in this array
  CHART_COLORS = ['#b35a94', '#1c5794', '#00b49e', '#6fac48', '#ebcf4a', '#fd7e33', '#ca3436', '#a26e3a']



  ### PUBLIC SCOPE ###

  ## ui-view transitions optimization: if true, the charts will never be refreshed
  $scope.preventRefresh = false

  ## statistics structure in elasticSearch
  $scope.statistics = []

  ## statistics data recovered from elasticSearch
  $scope.data = null

  ## default interval: one day
  $scope.display =
    interval: 'week'

  ## active tab will be set here
  $scope.selectedIndex = null

  ## for palmares graphs, filters values are stored here
  $scope.ranking =
    sortCriterion: 'ca'
    groupCriterion: 'subType'

  ## default: we do not open the datepicker menu
  $scope.datePicker =
    show: false

  ## datePicker parameters for interval beginning
  $scope.datePickerStart =
    format: Fablab.uibDateFormat
    opened: false # default: datePicker is not shown
    minDate: null
    maxDate: moment().subtract(1, 'day').toDate()
    selected: moment().utc().subtract(1, 'months').subtract(1, 'day').startOf('day').toDate()
    options:
      startingDay: Fablab.weekStartingDay

  ## datePicker parameters for interval ending
  $scope.datePickerEnd =
    format: Fablab.uibDateFormat
    opened: false # default: datePicker is not shown
    minDate: null
    maxDate: moment().subtract(1, 'day').toDate()
    selected: moment().subtract(1, 'day').endOf('day').toDate()
    options:
      startingDay: Fablab.weekStartingDay



  ##
  # Callback to open the datepicker (interval start)
  # @param {Object} jQuery event object
  ##
  $scope.toggleStartDatePicker = ($event) ->
    toggleDatePicker($event, $scope.datePickerStart)



  ##
  # Callback to open the datepicker (interval end)
  # @param {Object} jQuery event object
  ##
  $scope.toggleEndDatePicker = ($event) ->
    toggleDatePicker($event, $scope.datePickerEnd)



  ##
  # Callback called when the active tab is changed.
  # Recover the current tab and store its value in $scope.selectedIndex
  # @param tab {Object} elasticsearch statistic structure
  ##
  $scope.setActiveTab = (tab) ->
    $scope.selectedIndex = tab
    $scope.ranking.groupCriterion = 'subType'
    if tab.ca
      $scope.ranking.sortCriterion = 'ca'
    else
      $scope.ranking.sortCriterion = tab.types[0].key
    refreshChart()



  ##
  # Callback to close the date-picking popup and refresh the results
  ##
  $scope.validateDateChange = ->
    $scope.datePicker.show = false
    refreshChart()



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    Statistics.query (stats) ->
      $scope.statistics = stats
      # watch the interval changes to refresh the graph
      $scope.$watch (scope) ->
        return scope.display.interval
      , (newValue, oldValue) ->
        refreshChart()
      $scope.$watch (scope) ->
        return scope.ranking.sortCriterion
      , (newValue, oldValue) ->
        refreshChart()
      $scope.$watch (scope) ->
        return scope.ranking.groupCriterion
      , (newValue, oldValue) ->
        refreshChart()
      refreshChart()

    # workaround for angular-bootstrap::tabs behavior: on tab deletion, another tab will be selected
    # which will cause every tabs to reload, one by one, when the view is closed
    $rootScope.$on '$stateChangeStart', (event, toState, toParams, fromState, fromParams) ->
      if fromState.name == 'app.admin.stats_graphs' and Object.keys(fromParams).length == 0
        $scope.preventRefresh = true



  ##
  # Generic function to toggle a bootstrap datePicker
  # @param $event {Object} jQuery event object
  # @param datePicker {Object} settings object of the concerned datepicker. Must have an 'opened' property
  ##
  toggleDatePicker = ($event, datePicker) ->
    $event.preventDefault()
    $event.stopPropagation()
    datePicker.opened = !datePicker.opened



  ##
  # Query elasticSearch according to the current parameters and update the chart
  ##
  refreshChart = ->
    if $scope.selectedIndex and !$scope.preventRefresh
      query $scope.selectedIndex, (aggregations, error)->
        if error
          console.error(error)
        else
          if $scope.selectedIndex.graph.chart_type != 'discreteBarChart'
            $scope.data = formatAggregations(aggregations)
            angular.forEach $scope.data, (datum, key) ->
              updateChart($scope.selectedIndex.graph.chart_type, datum, key)
          else
            $scope.data = formatRankingAggregations(aggregations, $scope.selectedIndex.graph.limit, $scope.ranking.groupCriterion)
            updateChart($scope.selectedIndex.graph.chart_type, $scope.data.ranking, $scope.selectedIndex.es_type_key)



  ##
  # Callback used in NVD3 to print timestamps as literal dates on the X axis
  ##
  xAxisTickFormatFunction = (d, x, y) ->
    ### WARNING !! These tests (typeof/instanceof) may become broken on nvd3 update ###
    if $scope.display.interval == 'day'
      if typeof d == 'number' or d instanceof Date
        d3.time.format(Fablab.d3DateFormat) moment(d).toDate()
      else # typeof d == 'string'
        d
    else if $scope.display.interval == 'week'
      if typeof x == 'number' or d instanceof Date
        d3.time.format(_t('week_short')+' %U') moment(d).toDate()
      else if typeof d == 'number'
        _t('week_of_START_to_END', {START:moment(d).format('L'), END:moment(d).add(6, 'days').format('L')})
      else # typeof d == 'string'
        d
    else if $scope.display.interval == 'month'
      if typeof d == 'number'
        label = moment(d).format('MMMM YYYY')
        label.substr(0,1).toUpperCase()+label.substr(1).toLowerCase()
      else # typeof d == 'string'
        d



  ##
  # Format aggregations as retuned by elasticSearch to an understandable format for NVD3
  # @param aggs {Object} as returned by elasticsearch
  ##
  formatAggregations = (aggs) ->
    format = {}

    angular.forEach aggs, (type, type_key) -> # go through aggs[$TYPE] where $TYPE = month|year|hour|booking|...
      format[type_key] = []
      if type.subgroups
        angular.forEach type.subgroups.buckets, (subgroup) -> # go through aggs.$TYPE.subgroups.buckets where each bucket represent a $SUBTYPE
          angular.forEach $scope.selectedIndex.types, (cur_type) -> # in the mean time, go through the types of the current index (active tab) ...
            if cur_type.key == type_key  # ... looking for the type matching $TYPE
              for it_st in [0.. cur_type.subtypes.length-1] by 1 # when we've found it, iterate over its subtypes ...
                cur_subtype = cur_type.subtypes[it_st]
                if subgroup.key == cur_subtype.key # ... which match $SUBTYPE
                  # then we construct NVD3 dataSource according to these information
                  dataSource =
                    values: []
                    key: cur_subtype.label
                    total : 0
                    color: CHART_COLORS[it_st]
                    area: true
                  # finally, we iterate over 'intervals' buckets witch contains
                  # per date aggregations for our current dataSource
                  angular.forEach subgroup.intervals.buckets, (interval) ->
                    dataSource.values.push
                      x: interval.key
                      y: interval.total.value
                    dataSource.total += parseInt(interval.total.value)
                  dataSource.key += ' (' + dataSource.total + ')'
                  format[type_key].push dataSource
    format



  ##
  # Format aggregations for ranking charts to an understandable format for NVD3
  # @param aggs {Object} as returned by elasticsearch
  # @param limit {number} limit the number of stats in the bar chart
  # @param typeKey {String} field name witch results are grouped by
  ##
  formatRankingAggregations = (aggs, limit, typeKey) ->
    format =
      ranking: []

    it = 0
    while (it < aggs.subgroups.buckets.length)
      bucket = aggs.subgroups.buckets[it]
      dataSource =
        values: []
        key: getRankingLabel(bucket.key, typeKey)
        color: CHART_COLORS[it]
        area: true
      dataSource.values.push
        x: getRankingLabel(bucket.key, typeKey)
        y: bucket.total.value
      format.ranking.push(dataSource)
      it++
    getY = (object)->
      object.values[0].y
    format.ranking = stableSort(format.ranking, 'DESC', getY).slice(0, limit)
    for i in [0..format.ranking.length] by 1
      if typeof format.ranking[i] == 'undefined' then format.ranking.splice(i,1)
    format



  ##
  # For BarCharts, return the label for a given bar
  # @param key {string} raw value of the label
  # @param typeKey {string} name of the field the results are grouped by
  ##
  getRankingLabel = (key, typeKey) ->
    if $scope.selectedIndex
      if (typeKey == 'subType')
        for type in $scope.selectedIndex.types
          for subtype in type.subtypes
            if (subtype.key == key)
              return subtype.label
      else
        for field in $scope.selectedIndex.additional_fields
          if (field.key == typeKey)
            switch field.data_type
              when 'date' then return moment(key).format('LL')
              when 'list' then return key.name
              else return key



  ##
  # Prepare the elasticSearch query for the stats matching the current controller's parameters
  # @param index {{id:{number}, es_type_key:{string}, label:{string}, table:{boolean}, additional_fields:{Array},
  #   types:{Array}, graph:{Object}}} elasticSearch type in stats index to query
  # @param callback {function} function be to run after results were retrieved,
  #   it will receive two parameters : results {Array}, error {String} (if any)
  ##
  query = (index, callback) ->
    # invalid callback handeling
    if typeof(callback) != "function"
      console.error('[graphsController::query] Error: invalid callback provided')
      return
    if !index
      callback([], '[graphsController::query] Error: invalid index provided')
      return

    if index.graph.chart_type != 'discreteBarChart'
      # list statistics types
      stat_types = []
      for t in index.types
        if t.graph
          stat_types.push(t.key)

      # exception handeling
      if stat_types.length == 0
        callback([], "Error: Unable to retrieve any graphical statistic types in the provided index")

      type_it = 0
      results = {}
      error = ''
      recursiveCb = ->
        if type_it < stat_types.length
          queryElasticStats index.es_type_key, stat_types[type_it], (prevResults, prevError)->
            if (prevError)
              console.error('[graphsController::query] '+prevError)
              error += '\n'+prevError
            results[stat_types[type_it]] = prevResults
            type_it++
            recursiveCb()
        else
          callback(results)
      recursiveCb()
    else # palmares (ranking)
      queryElasticRanking index.es_type_key, $scope.ranking.groupCriterion, $scope.ranking.sortCriterion, (results, error) ->
        if (error)
          callback([], error)
        else
          callback(results)



  ##
  # Run the elasticSearch query to retreive the /stats/type aggregations
  # @param esType {String} elasticSearch document type (subscription|machine|training|...)
  # @param statType {String} statistics type (year|month|hour|booking|...)
  # @param callback {function} function be to run after results were retrieved,
  #   it will receive two parameters : results {Array}, error {String} (if any)
  ##
  queryElasticStats = (esType, statType, callback) ->
    # handle invalid callback
    if typeof(callback) != "function"
      console.error('[graphsController::queryElasticStats] Error: invalid callback provided')
      return
    if !esType or !statType
      callback([], '[graphsController::queryElasticStats] Error: invalid parameters provided')

    # run query
    es.search
      "index": "stats"
      "type": esType
      "searchType": "query_then_fetch"
      "size": 0
      "stat-type": statType
      "custom-query": ''
      "start-date": moment($scope.datePickerStart.selected).format()
      "end-date": moment($scope.datePickerEnd.selected).format()
      "body": buildElasticAggregationsQuery(statType, $scope.display.interval, moment($scope.datePickerStart.selected), moment($scope.datePickerEnd.selected))
    , (error, response) ->
      if (error)
        callback([], "Error: something unexpected occurred during elasticSearch query: "+error)
      else
        callback(response.aggregations)



  ##
  # For ranking displays, run the elasticSearch query to retreive the /stats/type aggregations
  # @param esType {string} elasticSearch document type (subscription|machine|training|...)
  # @param groupKey {string} statistics subtype or custom field
  # @param sortKey {string} statistics type or 'ca'
  # @param callback {function} function be to run after results were retrieved,
  # it will receive two parameters : results {Array}, error {String} (if any)
  ##
  queryElasticRanking = (esType, groupKey, sortKey, callback) ->
    # handle invalid callback
    if typeof(callback) != "function"
      return console.error('[graphsController::queryElasticRanking] Error: invalid callback provided')
    if !esType or !groupKey or !sortKey
      return callback([], '[graphsController::queryElasticRanking] Error: invalid parameters provided')

    # run query
    es.search
      "index": "stats"
      "type": esType
      "searchType": "query_then_fetch"
      "size": 0
      "body": buildElasticAggregationsRankingQuery(groupKey, sortKey, moment($scope.datePickerStart.selected), moment($scope.datePickerEnd.selected))
    , (error, response) ->
      if (error)
        callback([], "Error: something unexpected occurred during elasticSearch query: "+error)
      else
        callback(response.aggregations)



  ##
  # Parse a final elastic results bucket and return a D3 compatible object
  # @param bucket {{key_as_string:{String}, key:{Number}, doc_count:{Number}, total:{{value:{Number}}}}} interval bucket
  ##
  parseElasticBucket = (bucket) ->
    [ bucket.key, bucket.total.value ]



  ##
  # Build an object representing the content of the REST-JSON query to elasticSearch, based on the parameters
  # currently defined for data aggegations.
  # @param type {String} statistics type (visit|rdv|rating|ca|plan|account|search|...)
  # @param interval {String} statistics interval (year|quarter|month|week|day|hour|minute|second)
  # @param intervalBegin {moment} statitics interval beginning (moment.js type)
  # @param intervalEnd {moment} statitics interval ending (moment.js type)
  ##
  buildElasticAggregationsQuery = (type, interval, intervalBegin, intervalEnd) ->
    q =
      "query":
        "bool":
          "must": [
            {
              "match":
                "type": type
            }
            {
              "range":
                "date":
                  "gte": intervalBegin.format()
                  "lte": intervalEnd.format()
            }
          ]
      "aggregations":
        "subgroups":
          "terms":
            "field": "subType" #TODO allow aggregate by custom field
          "aggregations":
            "intervals":
              "date_histogram":
                "field": "date"
                "interval": interval
                "min_doc_count": 0
                "extended_bounds":
                  "min": intervalBegin.valueOf()
                  "max": intervalEnd.valueOf()
              "aggregations":
                "total":
                  "sum":
                    "field": "stat"

    # scale weeks on sunday as nvd3 supports only these weeks
    if interval == 'week'
      q.aggregations.subgroups.aggregations.intervals.date_histogram['offset'] = '-1d'
    # scale days to UTC time
    else if interval == 'day'
      offset = moment().utcOffset()
      q.aggregations.subgroups.aggregations.intervals.date_histogram['offset'] = (-offset)+'m'
    q



  ##
  # Build an object representing the content of the REST-JSON query to elasticSearch, based on the parameters
  # currently defined for data aggegations.
  # @param groupKey {String} statistics subtype or custom field
  # @param sortKey {String} statistics type or 'ca'
  # @param intervalBegin {moment} statitics interval beginning (moment.js type)
  # @param intervalEnd {moment} statitics interval ending (moment.js type)
  ##
  buildElasticAggregationsRankingQuery = (groupKey, sortKey, intervalBegin, intervalEnd) ->
    q =
      "query":
        "bool":
          "must": [
            {
              "range":
                "date":
                  "gte": intervalBegin.format()
                  "lte": intervalEnd.format()
            }
            {
              "term":
                "type": "booking"
            }
          ]
      "aggregations":
        "subgroups":
          "terms":
            "field": groupKey
            "size": 10
            "order":
              "total": "desc"
          "aggregations":
            "top_events":
              "top_hits":
                "size": 1
                "sort": [
                  { "ca": "desc" }
                ]
            "total":
              "sum":
                "field": "stat"

    # results must be sorted and limited later by angular
    if sortKey != 'ca'
      angular.forEach q.query.bool.must, (must) ->
        if must.term
          must.term.type = sortKey
    else
      q.aggregations.subgroups.aggregations.total.sum.field = sortKey

    q



  ##
  # Redraw the NDV3 chart using the provided data
  # @param chart_type {String} stackedAreaChart|discreteBarChart|lineChart
  # @param data {Array} array of NVD3 dataSources
  # @param type {String} which chart to update (statistic type key)
  ##
  updateChart = (chart_type, data, type) ->

    id = "#chart-"+type+" svg"

    # clean old charts
    d3.selectAll(id+" > *").remove()

    nv.addGraph ->
      # no data or many dates, display line charts
      if data.length == 0 or (data[0].values.length > 1 and (chart_type != 'discreteBarChart'))
        if chart_type == 'stackedAreaChart'
          chart = nv.models.stackedAreaChart().useInteractiveGuideline(true)
        else
          chart = nv.models.lineChart().useInteractiveGuideline(true)

        if data.length > 0
          if $scope.display.interval == 'day'
            setTimeScale(chart.xAxis, chart.xScale, [d3.time.day, data[0].values.length])
          else if $scope.display.interval == 'week'
            setTimeScale(chart.xAxis, chart.xScale, [d3.time.week, data[0].values.length])
          else if $scope.display.interval == 'month'
            setTimeScale(chart.xAxis, chart.xScale, [d3.time.month, data[0].values.length])

        chart.xAxis.tickFormat(xAxisTickFormatFunction)
        chart.yAxis.tickFormat(d3.format('d'))

        chart.xAxis.axisLabel(X_AXIS_LABEL)
        chart.yAxis.axisLabel(Y_AXIS_LABEL)

        # only one date, display histograms
      else
        chart = nv.models.discreteBarChart()
        chart.tooltip.enabled(false)
        chart.showValues(true)
        chart.x (d) -> d.label
        chart.y (d) -> d.value
        data = prepareDataForBarChart(data, type)

      # common for each charts
      chart.margin({left: 100, right: 100})
      chart.noData(_t('no_data_for_this_period'))
      chart.height( CHART_HEIGHT )

      # add new chart to the page
      d3.select(id).datum(data).transition().duration(350).call(chart)

      # resize the graph when the page is resized
      nv.utils.windowResize(chart.update)
      # return the chart
      chart



  ##
  # Given an NVD3 line chart axis, scale it to display ordinated dates, according to the given arguments
  ##
  setTimeScale = (nvd3Axis, nvd3Scale, argsArray)  ->
    scale = d3.time.scale()

    nvd3Axis.scale(scale)
    nvd3Scale(scale)

    if (not argsArray and not argsArray.length)
      oldTicks = nvd3Axis.axis.ticks
      nvd3Axis.axis.ticks = ->
        oldTicks.apply(nvd3Axis.axis, argsArray)



  ##
  # Translate line chart data in dates row to bar chart data, one bar per type.
  ##
  prepareDataForBarChart = (data, type) ->
    newData = [
      key: type
      values: []
    ]
    for info in data
      if info
        newData[0].values.push
          "label": info.key
          "value": info.values[0].y
          "color": info.color

    newData



  ##
  # Sort the provided array, in the specified order, on the value returned by the callback.
  # This is a stable-sorting algorithm implementation, ie. two call with the same array will return the same results
  # orders, especially with equal values.
  # @param array {Array} the array to sort
  # @param order {string} 'ASC' or 'DESC'
  # @param getValue {function} the callback which will return the value on which the sort will occurs
  # @returns {Array}
  ##
  stableSort = (array, order, getValue) ->
    # prepare sorting
    keys_order = []
    result = []
    for i in [0..array.length] by 1
      keys_order[array[i]] = i;
      result.push(array[i]);

    # callback for javascript native Array.sort()
    sort_fc = (a, b) ->
      val_a = getValue(a)
      val_b = getValue(b)
      if val_a == val_b
        return keys_order[a] - keys_order[b]
      if val_a < val_b
        if order == 'ASC' then return -1
        else return 1
      else
        if order == 'ASC' then return 1
        else return -1

    # finish the sort
    result.sort(sort_fc)
    return result



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]

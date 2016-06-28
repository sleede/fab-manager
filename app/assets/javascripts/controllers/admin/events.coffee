'use strict'

### COMMON CODE ###

##
# Provides a set of common properties and methods to the $scope parameter. They are used
# in the various events' admin controllers.
#
# Provides :
#  - $scope.categories = [{Category}]
#  - $scope.datePicker = {}
#  - $scope.submited(content)
#  - $scope.cancel()
#  - $scope.addFile()
#  - $scope.deleteFile(file)
#  - $scope.fileinputClass(v)
#  - $scope.toggleStartDatePicker($event)
#  - $scope.toggleEndDatePicker($event)
#  - $scope.toggleRecurrenceEnd(e)
#
# Requires :
#  - $scope.event.event_files_attributes = []
#  - $state (Ui-Router) [ 'app.public.events_list' ]
##
class EventsController
  constructor: ($scope, $state, Event, Category) ->

    ## Retrieve the list of categories from the server (course, workshop, ...)
    Category.query().$promise.then (data)->
      $scope.categories = data.map (d) ->
        id: d.id
        name: d.name

    ## default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker =
      format: Fablab.uibDateFormat
      startOpened: false # default: datePicker is not shown
      endOpened: false
      recurrenceEndOpened: false
      options:
        startingDay: Fablab.weekStartingDay



    ##
    # For use with ngUpload (https://github.com/twilson63/ngUpload).
    # Intended to be the callback when an upload is done: any raised error will be stacked in the
    # $scope.alerts array. If everything goes fine, the user is redirected to the project page.
    # @param content {Object} JSON - The upload's result
    ##
    $scope.submited = (content) ->
      if !content.id?
        $scope.alerts = []
        angular.forEach content, (v, k)->
          angular.forEach v, (err)->
            $scope.alerts.push({msg: k+': '+err, type: 'danger'})
      else
        $state.go('app.public.events_list')



    ##
    # Changes the user's view to the events list page
    ##
    $scope.cancel = ->
      $state.go('app.public.events_list')



    ##
    # For use with 'ng-class', returns the CSS class name for the uploads previews.
    # The preview may show a placeholder or the content of the file depending on the upload state.
    # @param v {*} any attribute, will be tested for truthiness (see JS evaluation rules)
    ##
    $scope.fileinputClass = (v)->
      if v
        'fileinput-exists'
      else
        'fileinput-new'



    ##
    # This will create a single new empty entry into the event's attachements list.
    ##
    $scope.addFile = ->
      $scope.event.event_files_attributes.push {}



    ##
    # This will remove the given file from the event's attachements list. If the file was previously uploaded
    # to the server, it will be marked for deletion on the server. Otherwise, it will be simply truncated from
    # the attachements array.
    # @param file {Object} the file to delete
    ##
    $scope.deleteFile = (file) ->
      index = $scope.event.event_files_attributes.indexOf(file)
      if file.id?
        file._destroy = true
      else
        $scope.event.event_files_attributes.splice(index, 1)



    ##
    # Show/Hide the "start" datepicker (open the drop down/close it)
    ##
    $scope.toggleStartDatePicker = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $scope.datePicker.startOpened = !$scope.datePicker.startOpened



    ##
    # Show/Hide the "end" datepicker (open the drop down/close it)
    ##
    $scope.toggleEndDatePicker = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $scope.datePicker.endOpened = !$scope.datePicker.endOpened



    ##
    # Masks/displays the recurrence pane allowing the admin to set the current event as recursive
    ##
    $scope.toggleRecurrenceEnd = (e)->
      e.preventDefault()
      e.stopPropagation()
      $scope.datePicker.recurrenceEndOpened = !$scope.datePicker.recurrenceEndOpened



##
# Controller used in the events listing page (admin view)
##
Application.Controllers.controller "AdminEventsController", ["$scope", "$state", 'Event', 'eventsPromise', ($scope, $state, Event, eventsPromise) ->



  ### PUBLIC SCOPE ###

  ## By default, the pagination mode is activated to limit the page size
  $scope.paginateActive = true

  ## The events displayed on the page
  $scope.events = eventsPromise

  ## Current virtual page
  $scope.page = 2

  ##
  # Adds a bucket of events to the bottom of the page, grouped by month
  ##
  $scope.loadMoreEvents = ->
    Event.query {page: $scope.page}, (data)->
      $scope.events = $scope.events.concat data
      paginationCheck(data, $scope.events)
    $scope.page += 1



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    paginationCheck(eventsPromise, $scope.events)


  ##
  # Check if all events are already displayed OR if the button 'load more events'
  # is required
  # @param lastEvents {Array} last events loaded onto the diplay (ie. last "page")
  # @param events {Array} full list of events displayed on the page (not only the last retrieved)
  ##
  paginationCheck = (lastEvents, events)->
    if lastEvents.length > 0
      $scope.paginateActive = false if events.length >= lastEvents[0].nb_total_events
    else
      $scope.paginateActive = false



  # init the controller (call at the end !)
  initialize()

]



##
# Controller used in the reservations listing page for a specific event
##
Application.Controllers.controller "ShowEventReservationsController", ["$scope", 'eventPromise', 'reservationsPromise', ($scope, eventPromise, reservationsPromise) ->

  ## retrieve the event from the ID provided in the current URL
  $scope.event = eventPromise

  ## list of reservations for the current event
  $scope.reservations = reservationsPromise
]



##
# Controller used in the event creation page
##
Application.Controllers.controller "NewEventController", ["$scope", "$state", "$locale", 'Event', 'Category', 'CSRF', '_t'
, ($scope, $state, $locale, Event, Category, CSRF, _t) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/events/"

  ## Form action on the above URL
  $scope.method = 'post'

  ## Default event parameters
  $scope.event =
    event_files_attributes: []
    start_date: new Date()
    end_date: new Date()
    start_time: new Date()
    end_time: new Date()
    all_day: 'false'
    recurrence: 'none'
    category_ids: []

  ## Possible types of recurrences for an event
  $scope.recurrenceTypes = [
    {label: _t('none'), value: 'none'},
    {label: _t('every_days'), value: 'day'},
    {label: _t('every_week'), value: 'week'},
    {label: _t('every_month'), value: 'month'},
    {label: _t('every_year'), value: 'year'}
  ]

  ## currency symbol for the current locale (cf. angular-i18n)
  $scope.currencySymbol = $locale.NUMBER_FORMATS.CURRENCY_SYM;

  ## Using the EventsController
  new EventsController($scope, $state, Event, Category)
]



##
# Controller used in the events edition page
##
Application.Controllers.controller "EditEventController", ["$scope", "$state", "$stateParams", "$locale", 'Event', 'Category', 'CSRF', 'eventPromise'
, ($scope, $state, $stateParams, $locale, Event, Category, CSRF, eventPromise) ->

  ### PUBLIC SCOPE ###



  ## API URL where the form will be posted
  $scope.actionUrl = "/api/events/" + $stateParams.id

  ## Form action on the above URL
  $scope.method = 'put'

  ## Retrieve the event details, in case of error the user is redirected to the events listing
  $scope.event = eventPromise

  ## currency symbol for the current locale (cf. angular-i18n)
  $scope.currencySymbol = $locale.NUMBER_FORMATS.CURRENCY_SYM;



  ### PRIVATE SCOPE ###



  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    CSRF.setMetaTags()

    # init the dates to JS objects
    $scope.event.start_date = moment($scope.event.start_date).toDate()
    $scope.event.end_date = moment($scope.event.end_date).toDate()

    ## Using the EventsController
    new EventsController($scope, $state, Event, Category)



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]

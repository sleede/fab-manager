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
#  - $scope.openStartDatePicker($event)
#  - $scope.openEndDatePicker($event)
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
      format: 'dd/MM/yyyy'
      startOpened: false # default: datePicker is not shown
      endOpened: false
      recurrenceEndOpened: false
      options:
        startingDay: 1 # France: the week starts on monday



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
Application.Controllers.controller "adminEventsController", ["$scope", "$state", 'Event', ($scope, $state, Event) ->



  ### PUBLIC SCOPE ###

  ## The events displayed on the page
  $scope.events = []

  ## By default, the pagination mode is activated to limit the page size
  $scope.paginateActive = true

  ## The currently displayed page number
  $scope.page = 1


  ##
  # Adds a bucket of events to the bottom of the page, grouped by month
  ##
  $scope.loadMoreEvents = ->
    Event.query {page: $scope.page}, (data)->
      $scope.events = $scope.events.concat data
      if data.length
      	$scope.paginateActive = false if $scope.events.length >= data[0].nb_total_events
      else
      	$scope.paginateActive = false
    $scope.page += 1



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    $scope.loadMoreEvents()

  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]



##
# Controller used in the event creation page
##
Application.Controllers.controller "newEventController", ["$scope", "$state", 'Event', 'Category', 'CSRF', ($scope, $state, Event, Category, CSRF) ->
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

  ## Possible types of recurrences for an event
  $scope.recurrenceTypes = [
    {label: 'None', value: 'none'},
    {label: 'Everyday', value: 'day'},
    {label: 'Every week', value: 'week'},
    {label: 'Each month', value: 'month'},
    {label: 'Every year', value: 'year'}
  ]

  ## Using the EventsController
  new EventsController($scope, $state, Event, Category)
]



##
# Controller used in the events edition page
##
Application.Controllers.controller "editEventController", ["$scope", "$state", "$stateParams", 'Event', 'Category', 'CSRF', ($scope, $state, $stateParams, Event, Category, CSRF) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/events/" + $stateParams.id

  ## Form action on the above URL
  $scope.method = 'put'

  ## Retrieve the event details, in case of error the user is redirected to the events listing
  Event.get {id: $stateParams.id}
  , (event)->
    $scope.event = event
    return
  , ->
    $state.go('app.public.events_list')

  ## Using the EventsController
  new EventsController($scope, $state, Event, Category)
]

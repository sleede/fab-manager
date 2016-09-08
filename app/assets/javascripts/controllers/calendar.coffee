'use strict'

##
# Controller used in the public calendar global
##

Application.Controllers.controller "CalendarController", ["$scope", "$state", "$aside", "moment", "Availability", 'Slot', 'Setting', 'growl', 'dialogs', 'bookingWindowStart', 'bookingWindowEnd', '_t', 'uiCalendarConfig', 'CalendarConfig', 'trainingsPromise', 'machinesPromise',
($scope, $state, $aside, moment, Availability, Slot, Setting, growl, dialogs, bookingWindowStart, bookingWindowEnd, _t, uiCalendarConfig, CalendarConfig, trainingsPromise, machinesPromise) ->


  ### PRIVATE STATIC CONSTANTS ###
  currentMachineEvent = null
  machinesPromise.forEach((m) -> m.checked = true)
  trainingsPromise.forEach((t) -> t.checked = true)

  ## check all formation/machine is select in filter
  isSelectAll = (type, scope) ->
    scope[type].length == scope[type].filter((t) -> t.checked).length

  ### PUBLIC SCOPE ###

  ## List of trainings
  $scope.trainings = trainingsPromise

  ## List of machines
  $scope.machines = machinesPromise

  ## add availabilities source to event sources
  $scope.eventSources = []

  ## filter availabilities if have change
  $scope.filterAvailabilities = (filter, scope) ->
    scope ||= $scope
    scope.filter = $scope.filter =
      trainings: isSelectAll('trainings', scope)
      machines: isSelectAll('machines', scope)
      evt: filter.evt
      dispo: filter.dispo
    $scope.calendarConfig.events = availabilitySourceUrl()


  ## a variable for formation/machine/event/dispo checkbox is or not checked
  $scope.filter =
    trainings: isSelectAll('trainings', $scope)
    machines: isSelectAll('machines', $scope)
    evt: true
    dispo: true

  ## toggle to select all formation/machine
  $scope.toggleFilter = (type, filter) ->
    $scope[type].forEach((t) -> t.checked = filter[type])
    $scope.filterAvailabilities(filter, $scope)

  $scope.openFilterAside = ->
    $aside.open
      templateUrl: 'filterAside.html'
      placement: 'right'
      size: 'md'
      backdrop: false
      resolve:
        trainings: ->
          $scope.trainings
        machines: ->
          $scope.machines
        filter: ->
          $scope.filter
        toggleFilter: ->
          $scope.toggleFilter
        filterAvailabilities: ->
          $scope.filterAvailabilities
      controller: ['$scope', '$uibModalInstance', 'trainings', 'machines', 'filter', 'toggleFilter', 'filterAvailabilities', ($scope, $uibModalInstance, trainings, machines, filter, toggleFilter, filterAvailabilities) ->
        $scope.trainings = trainings
        $scope.machines = machines
        $scope.filter = filter

        $scope.toggleFilter = (type, filter) ->
          toggleFilter(type, filter)

        $scope.filterAvailabilities = (filter) ->
          filterAvailabilities(filter, $scope)

        $scope.close = (e) ->
          $uibModalInstance.dismiss()
          e.stopPropagation()
      ]


  ### PRIVATE SCOPE ###

  calendarEventClickCb = (event, jsEvent, view) ->
    ## current calendar object
    calendar = uiCalendarConfig.calendars.calendar
    if event.available_type == 'machines'
      currentMachineEvent = event
      calendar.fullCalendar('changeView', 'agendaDay')
      calendar.fullCalendar('gotoDate', event.start)
    else
      if event.available_type == 'event'
        $state.go('app.public.events_show', {id: event.event_id})
      else if event.available_type == 'training'
        $state.go('app.public.training_show', {id: event.training_id})
      else
        $state.go('app.public.machines_show', {id: event.machine_id})

  ## agendaDay view: disable slotEventOverlap
  ## agendaWeek view: enable slotEventOverlap
  toggleSlotEventOverlap = (view) ->
    # set defaultView, because when we change slotEventOverlap
    # ui-calendar will trigger rerender calendar
    $scope.calendarConfig.defaultView = view.type
    today = if currentMachineEvent then currentMachineEvent.start else moment().utc().startOf('day')
    if today > view.start and today < view.end and today != view.start
      $scope.calendarConfig.defaultDate = today
    else
      $scope.calendarConfig.defaultDate = view.start
    if view.type == 'agendaDay'
      $scope.calendarConfig.slotEventOverlap = false
    else
      $scope.calendarConfig.slotEventOverlap = true

  ## function is called when calendar view is rendered or changed
  viewRenderCb = (view, element) ->
    toggleSlotEventOverlap(view)
    if view.type == 'agendaDay'
      # get availabilties by 1 day for show machine slots
      uiCalendarConfig.calendars.calendar.fullCalendar('refetchEvents')

  eventRenderCb = (event, element) ->
    if event.tags.length > 0
      html = ''
      for tag in event.tags
        html += "<span class='label label-success text-white'>#{tag.name}</span> "
      element.find('.fc-title').append("<br/>"+html)
    return

  getFilter = ->
    t = $scope.trainings.filter((t) -> t.checked).map((t) -> t.id)
    m = $scope.machines.filter((m) -> m.checked).map((m) -> m.id)
    {t: t, m: m, evt: $scope.filter.evt, dispo: $scope.filter.dispo}

  availabilitySourceUrl = ->
    "/api/availabilities/public?#{$.param(getFilter())}"

  initialize = ->
    ## fullCalendar (v2) configuration
    $scope.calendarConfig = CalendarConfig
      events: availabilitySourceUrl()
      slotEventOverlap: true
      header:
        left: 'month agendaWeek agendaDay'
        center: 'title'
        right: 'today prev,next'
      minTime: moment.duration(moment(bookingWindowStart.setting.value).format('HH:mm:ss'))
      maxTime: moment.duration(moment(bookingWindowEnd.setting.value).format('HH:mm:ss'))
      defaultView: if window.innerWidth <= 480 then 'agendaDay' else 'agendaWeek'
      eventClick: (event, jsEvent, view)->
        calendarEventClickCb(event, jsEvent, view)
      viewRender: (view, element) ->
        viewRenderCb(view, element)
      eventRender: (event, element, view) ->
        eventRenderCb(event, element)




  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]

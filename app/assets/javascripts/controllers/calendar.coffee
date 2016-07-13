'use strict'

##
# Controller used in the public calendar global
##

Application.Controllers.controller "CalendarController", ["$scope", "$state", "$uibModal", "moment", "Availability", 'Slot', 'Setting', 'growl', 'dialogs', 'bookingWindowStart', 'bookingWindowEnd', '_t', 'uiCalendarConfig', 'CalendarConfig'
($scope, $state, $uibModal, moment, Availability, Slot, Setting, growl, dialogs, bookingWindowStart, bookingWindowEnd, _t, uiCalendarConfig, CalendarConfig) ->


  ### PRIVATE STATIC CONSTANTS ###
  availableTypes = ['machines', 'training', 'event']
  availabilitySource =
    url: "/api/availabilities/public?#{$.param({available_type: availableTypes})}"
    textColor: 'black'
  currentMachineEvent = null


  ### PUBLIC SCOPE ###

  ## add availabilities source to event sources
  $scope.eventSources = []

  ## fullCalendar (v2) configuration
  $scope.calendarConfig = CalendarConfig
    events: availabilitySource.url
    slotEventOverlap: true
    header:
      left: 'month agendaWeek agendaDay'
      center: 'title'
      right: 'today prev,next'
    minTime: moment.duration(moment(bookingWindowStart.setting.value).format('HH:mm:ss'))
    maxTime: moment.duration(moment(bookingWindowEnd.setting.value).format('HH:mm:ss'))
    eventClick: (event, jsEvent, view)->
      calendarEventClickCb(event, jsEvent, view)
    viewRender: (view, element) ->
      viewRenderCb(view, element)
    eventRender: (event, element, view) ->
      eventRenderCb(event, element)

  $scope.filterAvailableType = (type) ->
    index = availableTypes.indexOf(type)
    if index != -1
      availableTypes.splice(index, 1)
    else
      availableTypes.push(type)
    availabilitySource.url = "/api/availabilities/public?#{$.param({available_type: availableTypes})}"
    $scope.calendarConfig.events = availabilitySource.url

  $scope.isAvailableTypeInactive = (type) ->
    index = availableTypes.indexOf(type)
    index == -1 ? true : false

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
    today = currentMachineEvent or moment().utc().startOf('day')
    if today > view.start and today <= view.end and today != view.start
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
]

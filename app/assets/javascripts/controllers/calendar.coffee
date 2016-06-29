'use strict'

##
# Controller used in the public calendar global
##

Application.Controllers.controller "CalendarController", ["$scope", "$state", "$uibModal", "moment", "Availability", 'Slot', 'Setting', 'growl', 'dialogs', 'bookingWindowStart', 'bookingWindowEnd', '_t', 'uiCalendarConfig', 'CalendarConfig'
($scope, $state, $uibModal, moment, Availability, Slot, Setting, growl, dialogs, bookingWindowStart, bookingWindowEnd, _t, uiCalendarConfig, CalendarConfig) ->


  ### PRIVATE STATIC CONSTANTS ###


  ### PUBLIC SCOPE ###

  ## add availabilities url to event sources
  $scope.eventSources = []
  $scope.eventSources.push
    url: '/api/availabilities/public'
    textColor: 'black'

  ## fullCalendar (v2) configuration
  $scope.calendarConfig = CalendarConfig
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


  ### PRIVATE SCOPE ###

  calendarEventClickCb = (event, jsEvent, view) ->
    ## current calendar object
    calendar = uiCalendarConfig.calendars.calendar
    if event.available_type == 'machines'
      calendar.fullCalendar('changeView', 'agendaDay')
      calendar.fullCalendar('gotoDate', event.start)
    else
      if event.available_type == 'event'
        $state.go('app.public.events_show', {id: event.event_id})

  ## agendaDay view: disable slotEventOverlap
  ## agendaWeek view: enable slotEventOverlap
  toggleSlotEventOverlap = (view) ->
    # set defaultView, because when we change slotEventOverlap
    # ui-calendar will trigger rerender calendar
    $scope.calendarConfig.defaultView = view.type
    today = moment().utc().startOf('day')
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
]

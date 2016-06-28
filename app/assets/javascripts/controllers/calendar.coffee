'use strict'

##
# Controller used in the public calendar global
##

Application.Controllers.controller "CalendarController", ["$scope", "$state", "$uibModal", "moment", "Availability", 'Slot', 'Setting', 'growl', 'dialogs', 'bookingWindowStart', 'bookingWindowEnd', '_t', 'uiCalendarConfig', 'CalendarConfig'
($scope, $state, $uibModal, moment, Availability, Slot, Setting, growl, dialogs, bookingWindowStart, bookingWindowEnd, _t, uiCalendarConfig, CalendarConfig) ->


  ### PRIVATE STATIC CONSTANTS ###


  ### PUBLIC SCOPE ###

  ## bind the availabilities slots with full-Calendar events
  $scope.eventSources = []
  $scope.eventSources.push
    url: '/api/availabilities/public'
    textColor: 'black'

  ## fullCalendar (v2) configuration
  $scope.calendarConfig = CalendarConfig
    slotEventOverlap: false
    header:
      left: 'month agendaWeek agendaDay'
      center: 'title'
      right: 'today prev,next'
    minTime: moment.duration(moment(bookingWindowStart.setting.value).format('HH:mm:ss'))
    maxTime: moment.duration(moment(bookingWindowEnd.setting.value).format('HH:mm:ss'))
    eventClick: (event, jsEvent, view)->
      calendarEventClickCb(event, jsEvent, view)
    viewRender: (view, element) ->
      if view.type == 'agendaDay'
        uiCalendarConfig.calendars.calendar.fullCalendar('refetchEvents')


  ### PRIVATE SCOPE ###

  calendarEventClickCb = (event, jsEvent, view) ->
    console.log event
    ## current calendar object
    calendar = uiCalendarConfig.calendars.calendar
    if event.available_type == 'machines'
      calendar.fullCalendar('gotoDate', event.start)
      calendar.fullCalendar('changeView', 'agendaDay')
    else
      if event.available_type == 'event'
        $state.go('app.public.events_show', {id: event.event_id})
]

'use strict'

##
# Controller used in the public calendar global
##

Application.Controllers.controller "CalendarController", ["$scope", "$uibModal", "moment", "Availability", 'Slot', 'Setting', 'growl', 'dialogs', 'bookingWindowStart', 'bookingWindowEnd', '_t', 'uiCalendarConfig', 'CalendarConfig'
($scope, $uibModal, moment, Availability, Slot, Setting, growl, dialogs, bookingWindowStart, bookingWindowEnd, _t, uiCalendarConfig, CalendarConfig) ->


  ### PRIVATE STATIC CONSTANTS ###



  ### PUBLIC SCOPE ###

  ## bind the availabilities slots with full-Calendar events
  $scope.eventSources = []
  $scope.eventSources.push
    url: '/api/availabilities/public'
    textColor: 'black'

  ## fullCalendar (v2) configuration
  $scope.calendarConfig = CalendarConfig
    header:
      left: 'month agendaWeek agendaDay'
      center: 'title'
      right: 'today prev,next'
    minTime: moment.duration(moment(bookingWindowStart.setting.value).format('HH:mm:ss'))
    maxTime: moment.duration(moment(bookingWindowEnd.setting.value).format('HH:mm:ss'))

]

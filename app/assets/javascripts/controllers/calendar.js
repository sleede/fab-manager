/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

//#
// Controller used in the public calendar global
//#

Application.Controllers.controller("CalendarController", ["$scope", "$state", "$aside", "moment", "Availability", 'Slot', 'Setting', 'growl', 'dialogs', 'bookingWindowStart', 'bookingWindowEnd', '_t', 'uiCalendarConfig', 'CalendarConfig', 'trainingsPromise', 'machinesPromise', 'spacesPromise',
function($scope, $state, $aside, moment, Availability, Slot, Setting, growl, dialogs, bookingWindowStart, bookingWindowEnd, _t, uiCalendarConfig, CalendarConfig, trainingsPromise, machinesPromise, spacesPromise) {


  /* PRIVATE STATIC CONSTANTS */
  let currentMachineEvent = null;
  machinesPromise.forEach(m => m.checked = true);
  trainingsPromise.forEach(t => t.checked = true);
  spacesPromise.forEach(s => s.checked = true);

  //# check all formation/machine is select in filter
  const isSelectAll = (type, scope) => scope[type].length === scope[type].filter(t => t.checked).length;

  /* PUBLIC SCOPE */

  //# List of trainings
  $scope.trainings = trainingsPromise.filter(t => !t.disabled);

  //# List of machines
  $scope.machines = machinesPromise.filter(t => !t.disabled);

  //# List of spaces
  $scope.spaces = spacesPromise.filter(t => !t.disabled);

  //# add availabilities source to event sources
  $scope.eventSources = [];

  //# filter availabilities if have change
  $scope.filterAvailabilities = function(filter, scope) {
    if (!scope) { scope = $scope; }
    scope.filter = ($scope.filter = {
      trainings: isSelectAll('trainings', scope),
      machines: isSelectAll('machines', scope),
      spaces: isSelectAll('spaces', scope),
      evt: filter.evt,
      dispo: filter.dispo
    });
    return $scope.calendarConfig.events = availabilitySourceUrl();
  };


  //# a variable for formation/machine/event/dispo checkbox is or not checked
  $scope.filter = {
    trainings: isSelectAll('trainings', $scope),
    machines: isSelectAll('machines', $scope),
    spaces: isSelectAll('spaces', $scope),
    evt: true,
    dispo: true
  };

  //# toggle to select all formation/machine
  $scope.toggleFilter = function(type, filter) {
    $scope[type].forEach(t => t.checked = filter[type]);
    return $scope.filterAvailabilities(filter, $scope);
  };

  $scope.openFilterAside = () =>
    $aside.open({
      templateUrl: 'filterAside.html',
      placement: 'right',
      size: 'md',
      backdrop: false,
      resolve: {
        trainings() {
          return $scope.trainings;
        },
        machines() {
          return $scope.machines;
        },
        spaces() {
          return $scope.spaces;
        },
        filter() {
          return $scope.filter;
        },
        toggleFilter() {
          return $scope.toggleFilter;
        },
        filterAvailabilities() {
          return $scope.filterAvailabilities;
        }
      },
      controller: ['$scope', '$uibModalInstance', 'trainings', 'machines', 'spaces', 'filter', 'toggleFilter', 'filterAvailabilities', function($scope, $uibModalInstance, trainings, machines, spaces, filter, toggleFilter, filterAvailabilities) {
        $scope.trainings = trainings;
        $scope.machines = machines;
        $scope.spaces = spaces;
        $scope.filter = filter;

        $scope.toggleFilter = (type, filter) => toggleFilter(type, filter);

        $scope.filterAvailabilities = filter => filterAvailabilities(filter, $scope);

        return $scope.close = function(e) {
          $uibModalInstance.dismiss();
          return e.stopPropagation();
        };
      }
      ]})
  ;


  /* PRIVATE SCOPE */

  const calendarEventClickCb = function(event, jsEvent, view) {
    //# current calendar object
    const { calendar } = uiCalendarConfig.calendars;
    if (event.available_type === 'machines') {
      currentMachineEvent = event;
      calendar.fullCalendar('changeView', 'agendaDay');
      return calendar.fullCalendar('gotoDate', event.start);
    } else if (event.available_type === 'space') {
      calendar.fullCalendar('changeView', 'agendaDay');
      return calendar.fullCalendar('gotoDate', event.start);
    } else if (event.available_type === 'event') {
      return $state.go('app.public.events_show', {id: event.event_id});
    } else if (event.available_type === 'training') {
      return $state.go('app.public.training_show', {id: event.training_id});
    } else {
      if (event.machine_id) {
        return $state.go('app.public.machines_show', {id: event.machine_id});
      } else if (event.space_id) {
        return $state.go('app.public.space_show', {id: event.space_id});
      }
    }
  };


  //# agendaDay view: disable slotEventOverlap
  //# agendaWeek view: enable slotEventOverlap
  const toggleSlotEventOverlap = function(view) {
    // set defaultView, because when we change slotEventOverlap
    // ui-calendar will trigger rerender calendar
    $scope.calendarConfig.defaultView = view.type;
    const today = currentMachineEvent ? currentMachineEvent.start : moment().utc().startOf('day');
    if ((today > view.intervalStart) && (today < view.intervalEnd) && (today !== view.intervalStart)) {
      $scope.calendarConfig.defaultDate = today;
    } else {
      $scope.calendarConfig.defaultDate = view.intervalStart;
    }
    if (view.type === 'agendaDay') {
      return $scope.calendarConfig.slotEventOverlap = false;
    } else {
      return $scope.calendarConfig.slotEventOverlap = true;
    }
  };

  //# function is called when calendar view is rendered or changed
  const viewRenderCb = function(view, element) {
    toggleSlotEventOverlap(view);
    if (view.type === 'agendaDay') {
      // get availabilties by 1 day for show machine slots
      return uiCalendarConfig.calendars.calendar.fullCalendar('refetchEvents');
    }
  };

  const eventRenderCb = function(event, element) {
    if (event.tags.length > 0) {
      let html = '';
      for (let tag of Array.from(event.tags)) {
        html += `<span class='label label-success text-white'>${tag.name}</span> `;
      }
      element.find('.fc-title').append(`<br/>${html}`);
    }
  };

  const getFilter = function() {
    const t = $scope.trainings.filter(t => t.checked).map(t => t.id);
    const m = $scope.machines.filter(m => m.checked).map(m => m.id);
    const s = $scope.spaces.filter(s => s.checked).map(s => s.id);
    return {t, m, s, evt: $scope.filter.evt, dispo: $scope.filter.dispo};
  };

  var availabilitySourceUrl = () => `/api/availabilities/public?${$.param(getFilter())}`;

  const initialize = () =>
    //# fullCalendar (v2) configuration
    $scope.calendarConfig = CalendarConfig({
      events: availabilitySourceUrl(),
      slotEventOverlap: true,
      header: {
        left: 'month agendaWeek agendaDay',
        center: 'title',
        right: 'today prev,next'
      },
      minTime: moment.duration(moment(bookingWindowStart.setting.value).format('HH:mm:ss')),
      maxTime: moment.duration(moment(bookingWindowEnd.setting.value).format('HH:mm:ss')),
      defaultView: window.innerWidth <= 480 ? 'agendaDay' : 'agendaWeek',
      eventClick(event, jsEvent, view){
        return calendarEventClickCb(event, jsEvent, view);
      },
      viewRender(view, element) {
        return viewRenderCb(view, element);
      },
      eventRender(event, element, view) {
        return eventRenderCb(event, element);
      }
    })
  ;




  //# !!! MUST BE CALLED AT THE END of the controller
  return initialize();
}
]);

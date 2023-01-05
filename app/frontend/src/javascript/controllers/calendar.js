/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/**
 * Controller used in the public calendar global
 */

Application.Controllers.controller('CalendarController', ['$scope', '$state', '$aside', 'moment', 'Availability', 'Setting', 'growl', 'dialogs', 'bookingWindowStart', 'bookingWindowEnd', '_t', 'uiCalendarConfig', 'CalendarConfig', 'trainingsPromise', 'machinesPromise', 'spacesPromise', 'iCalendarPromise', 'machineCategoriesPromise',
  function ($scope, $state, $aside, moment, Availability, Setting, growl, dialogs, bookingWindowStart, bookingWindowEnd, _t, uiCalendarConfig, CalendarConfig, trainingsPromise, machinesPromise, spacesPromise, iCalendarPromise, machineCategoriesPromise) {
  /* PRIVATE STATIC CONSTANTS */
    let currentMachineEvent = null;
    machinesPromise.forEach(m => m.checked = true);
    trainingsPromise.forEach(t => t.checked = true);
    spacesPromise.forEach(s => s.checked = true);

    // check all formation/machine is select in filter
    const isSelectAll = (type, scope) => scope[type].length === scope[type].filter(t => t.checked).length;

    /* PUBLIC SCOPE */

    // List of trainings
    $scope.trainings = trainingsPromise.filter(t => !t.disabled);

    // List of machines
    $scope.machines = machinesPromise.filter(t => !t.disabled);

    // List of machine categories
    $scope.machineCategories = machineCategoriesPromise;

    // List of machines group by category
    $scope.machinesGroupByCategory = [];

    // List of spaces
    $scope.spaces = spacesPromise.filter(t => !t.disabled);

    // List of external iCalendar sources
    $scope.externals = iCalendarPromise.map(e => Object.assign(e, { checked: true }));

    // add availabilities source to event sources
    $scope.eventSources = [];

    // filter availabilities if have change
    $scope.filterAvailabilities = function (filter, scope) {
      if (!scope) { scope = $scope; }
      scope.filter = ($scope.filter = {
        trainings: isSelectAll('trainings', scope),
        machines: isSelectAll('machines', scope),
        spaces: isSelectAll('spaces', scope),
        externals: isSelectAll('externals', scope),
        evt: filter.evt,
        dispo: filter.dispo
      });
      scope.machinesGroupByCategory.forEach(c => c.checked = _.every(c.machines, 'checked'));
      // remove all
      $scope.eventSources.splice(0, $scope.eventSources.length);
      // recreate source for trainings/machines/events with new filters
      $scope.eventSources.push({
        url: availabilitySourceUrl()
      });
      // external iCalendar events sources
      $scope.externals.forEach(e => {
        if (e.checked) {
          if (!$scope.eventSources.some(evt => evt.id === e.id)) {
            $scope.eventSources.push({
              id: e.id,
              url: `/api/i_calendar/${e.id}/events`,
              textColor: e.text_color || '#000',
              color: e.color
            });
          }
        } else {
          if ($scope.eventSources.some(evt => evt.id === e.id)) {
            const idx = $scope.eventSources.findIndex(evt => evt.id === e.id);
            $scope.eventSources.splice(idx, 1);
          }
        }
      });
      uiCalendarConfig.calendars.calendar.fullCalendar('refetchEvents');
    };

    /**
     * Return a CSS-like style of the given calendar configuration
     * @param calendar
     */
    $scope.calendarStyle = function (calendar) {
      return {
        'border-color': calendar.color,
        color: calendar.text_color
      };
    };

    // a variable for formation/machine/event/dispo checkbox is or not checked
    $scope.filter = {
      trainings: isSelectAll('trainings', $scope),
      machines: isSelectAll('machines', $scope),
      spaces: isSelectAll('spaces', $scope),
      externals: isSelectAll('externals', $scope),
      evt: true,
      dispo: true
    };

    // toggle to select all formation/machine
    $scope.toggleFilter = function (type, filter, machineCategoryId) {
      if (type === 'machineCategory') {
        const category = _.find($scope.machinesGroupByCategory, (c) => (c.id).toString() === machineCategoryId);
        if (category) {
          category.machines.forEach(m => m.checked = category.checked);
        }
        filter.machines = isSelectAll('machines', $scope);
      } else {
        $scope[type].forEach(t => t.checked = filter[type]);
        if (type === 'machines') {
          $scope.machinesGroupByCategory.forEach(t => t.checked = filter[type]);
        }
      }
      $scope.filterAvailabilities(filter, $scope);
    };

    $scope.openFilterAside = () =>
      $aside.open({
        templateUrl: '/calendar/filterAside.html',
        placement: 'right',
        size: 'md',
        backdrop: false,
        resolve: {
          trainings () {
            return $scope.trainings;
          },
          machines () {
            return $scope.machines;
          },
          machinesGroupByCategory () {
            return $scope.machinesGroupByCategory;
          },
          spaces () {
            return $scope.spaces;
          },
          externals () {
            return $scope.externals;
          },
          filter () {
            return $scope.filter;
          },
          toggleFilter () {
            return $scope.toggleFilter;
          },
          filterAvailabilities () {
            return $scope.filterAvailabilities;
          }
        },
        controller: ['$scope', '$uibModalInstance', 'trainings', 'machines', 'machinesGroupByCategory', 'spaces', 'externals', 'filter', 'toggleFilter', 'filterAvailabilities', 'AuthService', function ($scope, $uibModalInstance, trainings, machines, machinesGroupByCategory, spaces, externals, filter, toggleFilter, filterAvailabilities, AuthService) {
          $scope.trainings = trainings;
          $scope.machines = machines;
          $scope.machinesGroupByCategory = machinesGroupByCategory;
          $scope.hasMachineCategory = _.some(machines, 'machine_category_id');
          $scope.spaces = spaces;
          $scope.externals = externals;
          $scope.filter = filter;
          $scope.accordion = {
            trainings: false,
            machines: false,
            spaces: false
          };
          $scope.machinesGroupByCategory.forEach(c => $scope.accordion[c.name] = false);

          $scope.toggleAccordion = (type) => $scope.accordion[type] = !$scope.accordion[type];

          $scope.toggleFilter = (type, filter, machineCategoryId) => toggleFilter(type, filter, machineCategoryId);

          $scope.filterAvailabilities = filter => filterAvailabilities(filter, $scope);

          $scope.isAuthorized = AuthService.isAuthorized;

          return $scope.close = function (e) {
            $uibModalInstance.dismiss();
            return e.stopPropagation();
          };
        }]
      });

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = () => {
      // fullCalendar (v2) configuration
      $scope.calendarConfig = CalendarConfig({
        slotEventOverlap: true,
        header: {
          left: 'month agendaWeek agendaDay today prev,next',
          center: 'title',
          right: ''
        },
        minTime: moment.duration(moment(bookingWindowStart.setting.value).format('HH:mm:ss')),
        maxTime: moment.duration(moment(bookingWindowEnd.setting.value).format('HH:mm:ss')),
        defaultView: window.innerWidth <= 480 ? 'agendaDay' : 'agendaWeek',
        eventClick (event, jsEvent, view) {
          return calendarEventClickCb(event, jsEvent, view);
        },
        viewRender (view, element) {
          return viewRenderCb(view, element);
        },
        eventRender (event, element) {
          return eventRenderCb(event, element);
        }
      });
      $scope.eventSources = [{
        url: availabilitySourceUrl()
      }];
      $scope.externals.forEach(e => {
        if (e.checked) {
          $scope.eventSources.push({
            id: e.id,
            url: `/api/i_calendar/${e.id}/events`,
            textColor: e.text_color || '#000',
            color: e.color
          });
        }
      });

      // group machines by category
      _.forIn(_.groupBy($scope.machines, 'machine_category_id'), (ms, categoryId) => {
        const category = _.find($scope.machineCategories, (c) => (c.id).toString() === categoryId);
        $scope.machinesGroupByCategory.push({
          id: categoryId,
          name: category ? category.name : _t('app.shared.machine.machine_uncategorized'),
          checked: true,
          machine_ids: category ? category.machine_ids : [],
          machines: ms
        });
      });
    };

    /**
     * Callback triggered when an event object is clicked in the fullCalendar view
     */
    const calendarEventClickCb = function (event) {
      // current calendar object
      const { calendar } = uiCalendarConfig.calendars;
      if (event.available_type === 'machines') {
        currentMachineEvent = event;
        calendar.fullCalendar('changeView', 'agendaDay');
        calendar.fullCalendar('gotoDate', event.start);
      } else if (event.available_type === 'space') {
        calendar.fullCalendar('changeView', 'agendaDay');
        calendar.fullCalendar('gotoDate', event.start);
      } else if (event.available_type === 'event') {
        $state.go('app.public.events_show', { id: event.event_id });
      } else if (event.available_type === 'training') {
        $state.go('app.public.training_show', { id: event.training_id });
      } else {
        if (event.machine_ids) {
          // TODO open modal to ask the user to select the machine to show
          $state.go('app.public.machines_show', { id: event.machine_ids[0] });
        } else if (event.space_id) {
          $state.go('app.public.space_show', { id: event.space_id });
        }
      }
    };

    // agendaDay view: disable slotEventOverlap
    // agendaWeek view: enable slotEventOverlap
    const toggleSlotEventOverlap = function (view) {
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

    /**
     * This function is called when calendar view is rendered or changed
     * @see https://fullcalendar.io/docs/v3/viewRender#v2
     */
    const viewRenderCb = function (view) {
      toggleSlotEventOverlap(view);
      if (view.type === 'agendaDay') {
        // get availabilties by 1 day for show machine slots
        return uiCalendarConfig.calendars.calendar.fullCalendar('refetchEvents');
      }
    };

    /**
     * Callback triggered by fullCalendar when it is about to render an event.
     * @see https://fullcalendar.io/docs/v3/eventRender#v2
     */
    const eventRenderCb = function (event, element) {
      if (event.tags && event.tags.length > 0) {
        let html = '';
        for (const tag of Array.from(event.tags)) {
          html += `<span class='label label-success text-white'>${tag.name}</span> `;
        }
        element.find('.fc-title').append(`<br/>${html}`);
      }
    };

    const getFilter = function () {
      const t = $scope.trainings.filter(t => t.checked).map(t => t.id);
      const m = $scope.machines.filter(m => m.checked).map(m => m.id);
      const s = $scope.spaces.filter(s => s.checked).map(s => s.id);
      return { t, m, s, evt: $scope.filter.evt, dispo: $scope.filter.dispo };
    };

    const availabilitySourceUrl = () => `/api/availabilities/public?${$.param(getFilter())}`;

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

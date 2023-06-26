/* eslint-disable
    camelcase,
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/* COMMON CODE */

/**
 * Provides a set of common properties and methods to the $scope parameter. They are used
 * in the various events' admin controllers.
 *
 * Provides :
 *  - $scope.datePicker = {}
 *  - $scope.event_themes = []
 *  - $scope.submited(content)
 *  - $scope.cancel()
 *  - $scope.addFile()
 *  - $scope.deleteFile(file)
 *  - $scope.fileinputClass(v)
 *  - $scope.toggleStartDatePicker($event)
 *  - $scope.toggleEndDatePicker($event)
 *  - $scope.toggleRecurrenceEnd(e)
 *  - $scope.addPrice()
 *  - $scope.removePrice(price, $event)
 *  - $scope.handleEventChange(?)
 *
 * Requires :
 *  - $scope.event.event_files_attributes = []
 *  - $scope.event.
 *  - $state (Ui-Router) [ 'app.public.events_list' ]
 */
class EventsController {
  constructor ($scope, $state) {
    /**
     * Changes the user's view to the events list page
     */
    $scope.cancel = function () { $state.go('app.public.events_list'); };
  }
}

/**
 * Controller used in the events listing page (admin view)
 */
Application.Controllers.controller('AdminEventsController', ['$scope', '$state', 'dialogs', '$uibModal', 'growl', 'AuthService', 'Event', 'Category', 'EventTheme', 'AgeRange', 'PriceCategory', 'eventsPromise', 'categoriesPromise', 'themesPromise', 'ageRangesPromise', 'priceCategoriesPromise', '_t', 'Member', 'uiTourService', 'settingsPromise', '$uiRouter',
  function ($scope, $state, dialogs, $uibModal, growl, AuthService, Event, Category, EventTheme, AgeRange, PriceCategory, eventsPromise, categoriesPromise, themesPromise, ageRangesPromise, priceCategoriesPromise, _t, Member, uiTourService, settingsPromise, $uiRouter) {
  /* PUBLIC SCOPE */

    /**
   * Callback triggered by react components
   */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };

    // the following item is used by the UnsavedFormAlert component to detect a page change
    $scope.uiRouter = $uiRouter;

    /**
     * Callback triggered by react components
     */
    $scope.onError = function (message) {
      growl.error(message);
    };

    // By default, the pagination mode is activated to limit the page size
    $scope.paginateActive = true;

    // The events displayed on the page
    $scope.events = eventsPromise;

    // Current virtual page
    $scope.page = 1;

    // Temporary datastore for creating new elements
    $scope.inserted = {
      category: null,
      theme: null,
      age_range: null
    };

    // List of categories for the events
    $scope.categories = categoriesPromise;

    // List of events themes
    $scope.themes = themesPromise;

    // List of age ranges
    $scope.ageRanges = ageRangesPromise;

    // List of price categories for the events
    $scope.priceCategories = priceCategoriesPromise;

    // Default: we display all events (no restriction)
    $scope.eventsScope =
      { selected: '' };

    // default tab: events list
    $scope.tabs = { active: 1 };

    /**
     * Adds a bucket of events to the bottom of the page, grouped by month
     */
    $scope.loadMoreEvents = function () {
      $scope.page += 1;
      return Event.query({ page: $scope.page, scope: $scope.eventsScope.selected }, function (data) {
        $scope.events = $scope.events.concat(data);
        return paginationCheck(data, $scope.events);
      });
    };

    /**
     * Saves a new element / Update an existing one to the server (form validation callback)
     * @param model {string} model name
     * @param data {Object} element name
     * @param [id] {number} element id, in case of update
     */
    $scope.saveElement = function (model, data, id) {
      if (id != null) {
        return getModel(model)[0].update({ id }, data);
      } else {
        return getModel(model)[0].save(data, function (resp) { getModel(model)[1][getModel(model)[1].length - 1].id = resp.id; });
      }
    };

    /**
     * Deletes the element at the specified index
     * @param model {string} model name
     * @param index {number} element index in the $scope[model] array
     */
    $scope.removeElement = function (model, index) {
      if ((model === 'category') && (getModel(model)[1].length === 1)) {
        growl.error(_t('app.admin.events.at_least_one_category_is_required') + ' ' + _t('app.admin.events.unable_to_delete_the_last_one'));
        return false;
      }
      if (getModel(model)[1][index].related_to > 0) {
        growl.error(_t('app.admin.events.unable_to_delete_ELEMENT_already_in_use_NUMBER_times', { ELEMENT: model, NUMBER: getModel(model)[1][index].related_to }));
        return false;
      }
      return dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('app.admin.events.confirmation_required'),
              msg: _t('app.admin.events.do_you_really_want_to_delete_this_ELEMENT', { ELEMENT: model })
            };
          }
        }
      }
      , function () { // delete confirmed
        getModel(model)[0].delete(getModel(model)[1][index], null, function () { getModel(model)[1].splice(index, 1); }
          , function () { growl.error(_t('app.admin.events.unable_to_delete_an_error_occured')); });
      });
    };

    /**
     * Creates a new empty entry in the $scope[model] array
     * @param model {string} model name
     */
    $scope.addElement = function (model) {
      $scope.inserted[model] = {
        name: '',
        related_to: 0
      };
      return getModel(model)[1].push($scope.inserted[model]);
    };

    /**
     * Removes the newly inserted but not saved element / Cancel the current element modification
     * @param model {string} model name
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} element index in the $scope[model] array
     */
    $scope.cancelElement = function (model, rowform, index) {
      if (getModel(model)[1][index].id != null) {
        return rowform.$cancel();
      } else {
        return getModel(model)[1].splice(index, 1);
      }
    };

    /**
     * Open a modal dialog allowing the definition of a new price category.
     * Save it once filled and handle the result.
     */
    $scope.newPriceCategory = function () {
      $uibModal.open({
        templateUrl: '/admin/events/price_form.html',
        size: 'md',
        resolve: {
          category () { return {}; }
        },
        controller: 'PriceCategoryController'
      }).result.finally(null).then(function (p_cat) {
        // save the price category to the API
        PriceCategory.save(p_cat, function (cat) {
          $scope.priceCategories.push(cat);
          return growl.success(_t('app.admin.events.price_category_successfully_created'));
        }
        , function (err) {
          growl.error(_t('app.admin.events.unable_to_add_the_price_category_check_name_already_used'));
          return console.error(err);
        });
      });
    };
    /**
     * Update the given price category with the new properties
     * to specify in a modal dialog
     * @param index {number} index of the caterory in the $scope.priceCategories array
     * @param id {number} price category ID, must match the ID of the category at the index specified above
     */
    $scope.editPriceCategory = function (id, index) {
      if ($scope.priceCategories[index].id !== id) {
        return growl.error(_t('app.admin.events.unexpected_error_occurred_please_refresh'));
      } else {
        return $uibModal.open({
          templateUrl: '/admin/events/price_form.html',
          size: 'md',
          resolve: {
            category () { return $scope.priceCategories[index]; }
          },
          controller: 'PriceCategoryController'
        }).result.finally(null).then(function (p_cat) {
          // update the price category to the API
          PriceCategory.update({ id }, { price_category: p_cat }, function (cat) {
            $scope.priceCategories[index] = cat;
            return growl.success(_t('app.admin.events.price_category_successfully_updated'));
          }
          , function (err) {
            growl.error(_t('app.admin.events.unable_to_update_the_price_category'));
            return console.error(err);
          });
        });
      }
    };

    /**
     * Delete the given price category from the API
     * @param index {number} index of the caterory in the $scope.priceCategories array
     * @param id {number} price category ID, must match the ID of the category at the index specified above
     */
    $scope.removePriceCategory = function (id, index) {
      if ($scope.priceCategories[index].id !== id) {
        return growl.error(_t('app.admin.events.unexpected_error_occurred_please_refresh'));
      } else if ($scope.priceCategories[index].events > 0) {
        return growl.error(_t('app.admin.events.unable_to_delete_this_price_category_because_it_is_already_used'));
      } else {
        return dialogs.confirm(
          {
            resolve: {
              object () {
                return {
                  title: _t('app.admin.events.confirmation_required'),
                  msg: _t('app.admin.events.do_you_really_want_to_delete_this_price_category')
                };
              }
            }
          },
          function () { // delete confirmed
            PriceCategory.remove(
              { id },
              function () { // successfully deleted
                growl.success(_t('app.admin.events.price_category_successfully_deleted'));
                $scope.priceCategories.splice(index, 1);
              },
              function () { growl.error(_t('app.admin.events.price_category_deletion_failed')); }
            );
          }
        );
      }
    };

    /**
     * Triggered when the admin changes the events filter (all, passed, future).
     * We request the first page of corresponding events to the API
     */
    $scope.changeScope = function () {
      Event.query({ page: 1, scope: $scope.eventsScope.selected }, function (data) {
        $scope.events = data;
        return paginationCheck(data, $scope.events);
      });
      return $scope.page = 1;
    };

    /**
     * Setup the feature-tour for the admin/events page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupEventsTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('events');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.events.welcome.title'),
        content: _t('app.admin.tour.events.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.events-management .events-list',
        stepId: 'list',
        order: 1,
        title: _t('app.admin.tour.events.list.title'),
        content: _t('app.admin.tour.events.list.content'),
        placement: 'top'
      });
      uitour.createStep({
        selector: '.events-management .events-list-filter',
        stepId: 'filter',
        order: 2,
        title: _t('app.admin.tour.events.filter.title'),
        content: _t('app.admin.tour.events.filter.content'),
        placement: 'bottom'
      });
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: '.events-management .events-categories',
          stepId: 'categories',
          order: 3,
          title: _t('app.admin.tour.events.categories.title'),
          content: _t('app.admin.tour.events.categories.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.events-management .events-themes',
          stepId: 'themes',
          order: 4,
          title: _t('app.admin.tour.events.themes.title'),
          content: _t('app.admin.tour.events.themes.content'),
          placement: 'top'
        });
        uitour.createStep({
          selector: '.events-management .events-age-ranges',
          stepId: 'ages',
          order: 5,
          title: _t('app.admin.tour.events.ages.title'),
          content: _t('app.admin.tour.events.ages.content'),
          placement: 'top'
        });
        uitour.createStep({
          selector: '.events-management .prices-tab',
          stepId: 'prices',
          order: 6,
          title: _t('app.admin.tour.events.prices.title'),
          content: _t('app.admin.tour.events.prices.content'),
          placement: 'bottom'
        });
      }
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 7,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on step change, change the active tab if needed
      uitour.on('stepChanged', function (nextStep) {
        if (nextStep.stepId === 'list' || nextStep.stepId === 'filter') { $scope.tabs.active = 0; }
        if (nextStep.stepId === 'categories' || nextStep.stepId === 'ages') { $scope.tabs.active = 1; }
        if (nextStep.stepId === 'prices') { $scope.tabs.active = 2; }
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile_attributes.tours.indexOf('events') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'events' }, function (res) {
            $scope.currentUser.profile_attributes.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile_attributes.tours.indexOf('events') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      paginationCheck(eventsPromise, $scope.events);
    };

    /**
     * Check if all events are already displayed OR if the button 'load more events'
     * is required
     * @param lastEvents {Array} last events loaded onto the diplay (ie. last "page")
     * @param events {Array} full list of events displayed on the page (not only the last retrieved)
     */
    const paginationCheck = function (lastEvents, events) {
      if (lastEvents.length > 0) {
        if (events.length >= lastEvents[0].nb_total_events) {
          return $scope.paginateActive = false;
        } else {
          return $scope.paginateActive = true;
        }
      } else {
        return $scope.paginateActive = false;
      }
    };

    /**
     * Return the model and the datastore matching the given name
     * @param name {string} 'category', 'theme' or 'age_range'
     * @return {[Object, Array]} model and datastore
     */
    const getModel = function (name) {
      switch (name) {
        case 'category': return [Category, $scope.categories];
        case 'theme': return [EventTheme, $scope.themes];
        case 'age_range': return [AgeRange, $scope.ageRanges];
        default: return [null, []];
      }
    };

    // init the controller (call at the end !)
    return initialize();
  }

]);

/**
 * Controller used in the reservations listing page for a specific event
 */
Application.Controllers.controller('ShowEventReservationsController', ['$scope', 'eventPromise', 'reservationsPromise', 'dialogs', 'SlotsReservation', 'growl', '_t', function ($scope, eventPromise, reservationsPromise, dialogs, SlotsReservation, growl, _t) {
  // retrieve the event from the ID provided in the current URL
  $scope.event = eventPromise;

  // list of reservations for the current event
  $scope.reservations = reservationsPromise;

  /**
   * Test if the provided reservation has been cancelled
   * @param reservation {Reservation}
   * @returns {boolean}
   */
  $scope.isCancelled = function (reservation) {
    return !!(reservation.slots_reservations_attributes[0].canceled_at);
  };

  /**
   * Test if the provided reservation has been validated
   * @param reservation {Reservation}
   * @returns {boolean}
   */
  $scope.isValidated = function (reservation) {
    return !!(reservation.slots_reservations_attributes[0].validated_at);
  };

  /**
   * Callback to validate a reservation
   * @param reservation {Reservation}
   */
  $scope.validateReservation = function (reservation) {
    dialogs.confirm({
      resolve: {
        object: function () {
          return {
            title: _t('app.admin.event_reservations.validate_the_reservation'),
            msg: _t('app.admin.event_reservations.do_you_really_want_to_validate_this_reservation_this_apply_to_all_booked_tickets')
          };
        }
      }
    }, function () { // validate confirmed
      SlotsReservation.validate({
        id: reservation.slots_reservations_attributes[0].id
      }, () => { // successfully validated
        growl.success(_t('app.admin.event_reservations.reservation_was_successfully_validated'));
        const index = $scope.reservations.indexOf(reservation);
        $scope.reservations[index].slots_reservations_attributes[0].validated_at = new Date();
      }, () => {
        growl.warning(_t('app.admin.event_reservations.validation_failed'));
      });
    });
  };
}]);

/**
 * Controller used in the event creation page
 */
Application.Controllers.controller('NewEventController', ['$scope', '$state', 'CSRF', 'growl',
  function ($scope, $state, CSRF, growl) {
    CSRF.setMetaTags();

    /**
     * Callback triggered by react components
     */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };

    /**
     * Callback triggered by react components
     */
    $scope.onError = function (message) {
      console.error(message);
      growl.error(message);
    };

    // Using the EventsController
    return new EventsController($scope, $state);
  }
]);

/**
 * Controller used in the events edition page
 */
Application.Controllers.controller('EditEventController', ['$scope', '$state', 'CSRF', 'eventPromise', 'growl',
  function ($scope, $state, CSRF, eventPromise, growl) {
    /* PUBLIC SCOPE */

    // Retrieve the event details, in case of error the user is redirected to the events listing
    $scope.event = cleanEvent(eventPromise);

    /**
     * Callback triggered by react components
     */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };

    /**
     * Callback triggered by react components
     */
    $scope.onError = function (message) {
      console.error(message);
      growl.error(message);
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      CSRF.setMetaTags();

      // Using the EventsController
      return new EventsController($scope, $state);
    };

    // prepare the event for the react-hook-form
    function cleanEvent (event) {
      delete event.$promise;
      delete event.$resolved;
      return event;
    }

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the event edit-mode modal window
 */
Application.Controllers.controller('EditRecurrentEventController', ['$scope', '$uibModalInstance', 'editMode', 'growl', 'initialDates', 'currentEvent', '_t',
  function ($scope, $uibModalInstance, editMode, growl, initialDates, currentEvent, _t) {
    // with recurrent slots: how many slots should we update?
    $scope.editMode = editMode;

    /**
     * Confirmation callback
     */
    $scope.ok = function () {
      $uibModalInstance.close({
        editMode: $scope.editMode
      });
    };

    /**
     * Test if any of the dates of the event has changed
     */
    $scope.hasDateChanged = function () {
      return (!moment(initialDates.start).isSame(currentEvent.start_date, 'day') || !moment(initialDates.end).isSame(currentEvent.end_date, 'day'));
    };

    /**
     * Cancellation callback
     */
    $scope.cancel = function () {
      $uibModalInstance.dismiss('cancel');
    };
  }
]);

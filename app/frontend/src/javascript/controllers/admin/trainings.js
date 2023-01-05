/* eslint-disable
    handle-callback-err,
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/* COMMON CODE */

/**
 * Provides a set of common callback methods to the $scope parameter. These methods are used
 * in the various trainings' admin controllers.
 *
 * Provides :
 *  - $scope.submited(content)
 *  - $scope.fileinputClass(v)
 *  - $scope.onDisableToggled
 *
 * Requires :
 *  - $state (Ui-Router) [ 'app.admin.trainings' ]
 *  - $scope.training
 */
class TrainingsController {
  constructor ($scope, $state) {
    /*
     * For use with ngUpload (https://github.com/twilson63/ngUpload).
     * Intended to be the callback when the upload is done: any raised error will be stacked in the
     * $scope.alerts array. If everything goes fine, the user is redirected to the trainings list.
     * @param content {Object} JSON - The upload's result
     */
    $scope.submited = function (content) {
      if ((content.id == null)) {
        $scope.alerts = [];
        return angular.forEach(content, function (v, k) {
          angular.forEach(v, function (err) {
            $scope.alerts.push({
              msg: k + ': ' + err,
              type: 'danger'
            });
          });
        });
      } else {
        return $state.go('app.admin.trainings');
      }
    };

    /**
     * Changes the current user's view, redirecting him to the machines list
     */
    $scope.cancel = function () { $state.go('app.admin.trainings'); };

    /**
     * Force the 'public_page' attribute to false when the current training is disabled
     */
    $scope.onDisableToggled = function () { $scope.training.public_page = !$scope.training.disabled; };

    /**
     * For use with 'ng-class', returns the CSS class name for the uploads previews.
     * The preview may show a placeholder or the content of the file depending on the upload state.
     * @param v {*} any attribute, will be tested for truthiness (see JS evaluation rules)
     */
    $scope.fileinputClass = function (v) {
      if (v) {
        return 'fileinput-exists';
      } else {
        return 'fileinput-new';
      }
    };
  }
}

/**
 * Controller used in the training creation page (admin)
 */
Application.Controllers.controller('NewTrainingController', ['$scope', '$state', 'CSRF', 'growl',
  function ($scope, $state, CSRF, growl) {
    /* PUBLIC SCOPE */

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
      growl.error(message);
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      CSRF.setMetaTags();

      // Using the TrainingsController
      return new TrainingsController($scope, $state);
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the training edition page (admin)
 */
Application.Controllers.controller('EditTrainingController', ['$scope', '$state', '$transition$', 'trainingPromise', 'CSRF', 'growl',
  function ($scope, $state, $transition$, trainingPromise, CSRF, growl) {
    /* PUBLIC SCOPE */

    // Details of the training to edit (id in URL)
    $scope.training = cleanTraining(trainingPromise);

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
      growl.error(message);
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      CSRF.setMetaTags();

      // Using the TrainingsController
      return new TrainingsController($scope, $state);
    };

    // prepare the training for the react-hook-form
    function cleanTraining (training) {
      delete training.$promise;
      delete training.$resolved;
      return training;
    }

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the trainings management page, allowing admins users to see and manage the list of trainings and reservations.
 */
Application.Controllers.controller('TrainingsAdminController', ['$scope', '$state', '$uibModal', 'Training', 'trainingsPromise', 'machinesPromise', '_t', 'growl', 'dialogs', 'Member', 'uiTourService', 'settingsPromise',
  function ($scope, $state, $uibModal, Training, trainingsPromise, machinesPromise, _t, growl, dialogs, Member, uiTourService, settingsPromise) {
    // list of trainings
    $scope.trainings = trainingsPromise;

    // simplified list of machines
    $scope.machines = machinesPromise;

    // Training to monitor, bound with drop-down selection
    $scope.monitoring = { training: null };

    // list of training availabilities, grouped by date
    $scope.groupedAvailabilities = {};

    // default: accordions are not open
    $scope.accordions = {};

    // Binding for the parseInt function
    $scope.parseInt = parseInt;

    // Default: we show only enabled trainings
    $scope.trainingFiltering = 'enabled';

    // Available options for filtering trainings by status
    $scope.filterDisabled = [
      'enabled',
      'disabled',
      'all'
    ];

    // default tab: trainings list
    $scope.tabs = { active: 0 };

    $scope.enableMachinesModule = settingsPromise.machines_module === 'true';

    /**
     * In the trainings listing tab, return the stringified list of machines associated with the provided training
     * @param training {Object} Training object, inherited from $resource
     * @returns {string}
     */
    $scope.showMachines = function (training) {
      const selected = [];
      angular.forEach($scope.machines, function (m) {
        if (training.machine_ids.indexOf(m.id) >= 0) {
          return selected.push(m.name);
        }
      });
      if (selected.length) { return selected.join(', '); } else { return _t('app.admin.trainings.none'); }
    };

    /**
     * Removes the newly inserted but not saved training / Cancel the current training modification
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} training index in the $scope.trainings array
     */
    $scope.cancelTraining = function (rowform, index) {
      if ($scope.trainings[index].id != null) {
        return rowform.$cancel();
      } else {
        return $scope.trainings.splice(index, 1);
      }
    };

    /**
     * In the trainings monitoring tab, callback to open a modal window displaying the current bookings for the
     * provided training slot. The admin will be then able to validate the training for the users that followed
     * the training.
     * @param training {Object} Training object, inherited from $resource
     * @param availability {Object} time slot when the training occurs
     */
    $scope.showReservations = function (training, availability) {
      $uibModal.open({
        templateUrl: '/admin/trainings/validTrainingModal.html',
        controller: ['$scope', '$uibModalInstance', function ($scope, $uibModalInstance) {
          $scope.availability = availability;

          $scope.usersToValid = [];

          /**
           * Mark/unmark the provided user for training validation
           * @param user {Object} from the availability.reservation_users list
           */
          $scope.toggleSelection = function (user) {
            const index = $scope.usersToValid.indexOf(user);
            if (index > -1) {
              return $scope.usersToValid.splice(index, 1);
            } else {
              return $scope.usersToValid.push(user);
            }
          };

          /**
           * Validates the modifications (training validations) and save them to the server
           */
          $scope.ok = function () {
            const users = $scope.usersToValid.map(function (u) { return u.id; });
            return Training.update({ id: training.id }, {
              training: {
                users
              }
            }
            , function () { // success
              angular.forEach($scope.usersToValid, function (u) { u.is_valid = true; });
              $scope.usersToValid = [];
              return $uibModalInstance.close(training);
            });
          };

          /**
           * Cancel the modifications and close the modal window
           */
          return $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }
        ]
      });
    };

    /**
     * Delete the provided training and, in case of success, remove it from the trainings list afterwards
     * @param index {number} index of the provided training in $scope.trainings
     * @param training {Object} training to delete
     */
    $scope.removeTraining = function (index, training) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.trainings.confirmation_required'),
                msg: _t('app.admin.trainings.do_you_really_want_to_delete_this_training')
              };
            }
          }
        },
        function () { // deletion confirmed
          training.$delete(function () {
            $scope.trainings.splice(index, 1);
            growl.info(_t('app.admin.trainings.training_successfully_deleted'));
          },
          function (error) {
            growl.warning(_t('app.admin.trainings.unable_to_delete_the_training_because_some_users_already_booked_it'));
            console.error(error);
          });
        }
      );
    };

    /**
     * Takes a month number and return its localized literal name
     * @param number {Number} from 0 to 11
     * @returns {String} eg. 'janvier'
     */
    $scope.formatMonth = function (number) {
      number = parseInt(number);
      return moment().month(number).format('MMMM');
    };

    /**
     * Given a day, month and year, return a localized literal name for the day
     * @param day {Number} from 1 to 31
     * @param month {Number} from 0 to 11
     * @param year {Number} Gregorian's year number
     * @returns {String} eg. 'mercredi 12'
     */
    $scope.formatDay = function (day, month, year) {
      day = parseInt(day);
      month = parseInt(month);
      year = parseInt(year);

      return moment({ year, month, day }).format('dddd D');
    };

    /**
     * Callback when the drop-down selection is changed.
     * The selected training details will be loaded from the API and rendered into the accordions.
     */
    $scope.selectTrainingToMonitor = function () {
      Training.availabilities({ id: $scope.monitoring.training.id }, function (training) {
        $scope.groupedAvailabilities = groupAvailabilities([training]);
        // we open current year/month by default
        const now = moment();
        $scope.accordions[training.name] = {};
        $scope.accordions[training.name][now.year()] = { isOpenFirst: true };
        $scope.accordions[training.name][now.year()][now.month()] = { isOpenFirst: true };
      });
    };

    /**
     * Setup the feature-tour for the admin/trainings page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupTrainingsTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('trainings');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.trainings.welcome.title'),
        content: _t('app.admin.tour.trainings.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.trainings-monitoring .manage-trainings',
        stepId: 'trainings',
        order: 1,
        title: _t('app.admin.tour.trainings.trainings.title'),
        content: _t('app.admin.tour.trainings.trainings.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.trainings-monitoring .filter-trainings',
        stepId: 'filter',
        order: 2,
        title: _t('app.admin.tour.trainings.filter.title'),
        content: _t('app.admin.tour.trainings.filter.content'),
        placement: 'left'
      });
      uitour.createStep({
        selector: '.trainings-monitoring .post-tracking',
        stepId: 'tracking',
        order: 3,
        title: _t('app.admin.tour.trainings.tracking.title'),
        content: _t('app.admin.tour.trainings.tracking.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 4,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on step change, change the active tab if needed
      uitour.on('stepChanged', function (nextStep) {
        if (nextStep.stepId === 'filter' || nextStep.stepId === 'machines') { $scope.tabs.active = 0; }
        if (nextStep.stepId === 'tracking') { $scope.tabs.active = 1; }
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile_attributes.tours.indexOf('trainings') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'trainings' }, function (res) {
            $scope.currentUser.profile_attributes.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile_attributes.tours.indexOf('trainings') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {};

    /**
     * Group the trainings availabilities by trainings and by dates and return the resulting tree
     * @param trainings {Array} $scope.trainings is expected here
     * @returns {Object} Tree constructed as /training_name/year/month/day/[availabilities]
     */
    const groupAvailabilities = function (trainings) {
      const tree = {};
      for (const training of Array.from(trainings)) {
        tree[training.name] = {};
        tree[training.name].training = training;
        for (const availability of Array.from(training.availabilities)) {
          const start = moment(availability.start_at);

          // init the tree structure
          if (typeof tree[training.name][start.year()] === 'undefined') {
            tree[training.name][start.year()] = {};
          }
          if (typeof tree[training.name][start.year()][start.month()] === 'undefined') {
            tree[training.name][start.year()][start.month()] = {};
          }
          if (typeof tree[training.name][start.year()][start.month()][start.date()] === 'undefined') {
            tree[training.name][start.year()][start.month()][start.date()] = [];
          }

          // add the availability at its right place
          tree[training.name][start.year()][start.month()][start.date()].push(availability);
        }
      }
      return tree;
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }

]);

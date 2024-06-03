/* eslint-disable
    handle-callback-err,
    no-return-assign,
    no-self-assign,
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
 * Provides a set of common properties and methods to the $scope parameter. They are used
 * in the various members' admin controllers.
 *
 * Provides :
 *  - $scope.groups = [{Group}]
 *  - $scope.trainings = [{Training}]
 *  - $scope.plans = []
 *  - $scope.datePicker = {}
 *  - $scope.submited(content)
 *  - $scope.cancel()
 *  - $scope.fileinputClass(v)
 *  - $scope.openDatePicker($event)
 *  - $scope.openSubscriptionDatePicker($event)
 *
 * Requires :
 *  - $state (Ui-Router) [ 'app.admin.members' ]
 */
class MembersController {
  constructor ($scope, $state, Group, Training) {
    // Retrieve the profiles groups (e.g. students ...)
    Group.query(function (groups) { $scope.groups = groups.filter(function (g) { return !g.disabled; }); });

    // Retrieve the list of available trainings
    Training.query().$promise.then(function (data) {
      $scope.trainings = data.map(function (d) {
        return ({
          id: d.id,
          name: d.name,
          disabled: d.disabled
        });
      });
    });

    // Default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      opened: false, // default: datePicker is not shown
      subscription_date_opened: false,
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    /**
     * Shows the birthday datepicker
     * @param $event {Object} jQuery event object
     */
    $scope.openDatePicker = function ($event) {
      $event.preventDefault();
      $event.stopPropagation();
      return $scope.datePicker.opened = true;
    };

    /**
     * Shows the end of subscription datepicker
     * @param $event {Object} jQuery event object
     */
    $scope.openSubscriptionDatePicker = function ($event) {
      $event.preventDefault();
      $event.stopPropagation();
      return $scope.datePicker.subscription_date_opened = true;
    };

    /**
     * For use with ngUpload (https://github.com/twilson63/ngUpload).
     * Intended to be the callback when an upload is done: any raised error will be stacked in the
     * $scope.alerts array. If everything goes fine, the user is redirected to the members listing page.
     * @param content {Object} JSON - The result of the upload
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
        return $state.go('app.admin.members');
      }
    };

    /**
     * Changes the admin's view to the members list page
     */
    $scope.cancel = function () { $state.go('app.admin.members'); };

    /**
     * For use with 'ng-class', returns the CSS class name for the uploads previews.
     * The preview may show a placeholder, or the content of the file depending on the upload state.
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
 * Controller used in the members/groups management page
 */
Application.Controllers.controller('AdminMembersController', ['$scope', '$sce', '$uibModal', 'membersPromise', 'adminsPromise', 'partnersPromise', 'managersPromise', 'growl', 'Admin', 'AuthService', 'dialogs', '_t', 'Member', 'Export', 'User', 'uiTourService', 'settingsPromise', '$location',
  function ($scope, $sce, $uibModal, membersPromise, adminsPromise, partnersPromise, managersPromise, growl, Admin, AuthService, dialogs, _t, Member, Export, User, uiTourService, settingsPromise, $location) {
  /* PRIVATE STATIC CONSTANTS */

    // number of users loaded each time we click on 'load more...'
    const USERS_PER_PAGE = 20;

    /* PUBLIC SCOPE */

    // members list
    $scope.members = membersPromise;

    $scope.member = {
    // Members plain-text filtering. Default: not filtered
      searchText: '',
      // Members ordering/sorting. Default: not sorted
      order: 'id',
      // the currently displayed page of members
      page: 1,
      // true when all members where loaded
      noMore: false,
      // default filter for members
      memberFilter: 'all',
      // options for members filtering
      memberFilters: [
        'all',
        'not_confirmed',
        'inactive_for_3_years'
      ]
    };

    // admins list
    $scope.admins = adminsPromise.admins.filter(function (m) { return m.id !== Fablab.adminSysId; });

    // is user validation required
    $scope.enableUserValidationRequired = (settingsPromise.user_validation_required === 'true');

    if ($scope.enableUserValidationRequired) { $scope.member.memberFilters.push('not_validated'); }

    // Admins ordering/sorting. Default: not sorted
    $scope.orderAdmin = null;

    // partners list
    $scope.partners = partnersPromise;

    // Partners ordering/sorting. Default: not sorted
    $scope.orderPartner = null;

    // managers list
    $scope.managers = managersPromise;

    // Managers ordering/sorting. Default: not sorted
    $scope.orderManager = null;

    // default tab: members list
    const defaultActiveTab = $location.search().tabs ? parseInt($location.search().tabs, 10) : 0;
    $scope.tabs = { active: defaultActiveTab, sub: 0 };

    /**
     * Change the members ordering criterion to the one provided
     * @param orderBy {string} ordering criterion
     */
    $scope.setOrderMember = function (orderBy) {
      if ($scope.member.order === orderBy) {
        $scope.member.order = `-${orderBy}`;
      } else {
        $scope.member.order = orderBy;
      }

      resetSearchMember();
      return memberSearch();
    };

    /**
     * Change the admins ordering criterion to the one provided
     * @param orderAdmin {string} ordering criterion
     */
    $scope.setOrderAdmin = function (orderAdmin) {
      if ($scope.orderAdmin === orderAdmin) {
        return $scope.orderAdmin = `-${orderAdmin}`;
      } else {
        return $scope.orderAdmin = orderAdmin;
      }
    };

    /**
     * Change the partners ordering criterion to the one provided
     * @param orderPartner {string} ordering criterion
     */
    $scope.setOrderPartner = function (orderPartner) {
      if ($scope.orderPartner === orderPartner) {
        return $scope.orderPartner = `-${orderPartner}`;
      } else {
        return $scope.orderPartner = orderPartner;
      }
    };

    /**
     * Change the managers ordering criterion to the one provided
     * @param orderManager {string} ordering criterion
     */
    $scope.setOrderManager = function (orderManager) {
      if ($scope.orderManager === orderManager) {
        return $scope.orderManager = `-${orderManager}`;
      } else {
        return $scope.orderManager = orderManager;
      }
    };

    /**
     * Open a modal dialog allowing the admin to create a new partner user
     */
    $scope.openPartnerNewModal = function () {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: '/shared/_partner_new_modal.html',
        size: 'lg',
        controller: ['$scope', '$uibModalInstance', 'User', function ($scope, $uibModalInstance, User) {
          $scope.partner = {};

          $scope.ok = function () {
            User.save(
              {},
              { user: $scope.partner },
              function (user) {
                $scope.partner.id = user.id;
                $scope.partner.name = `${user.first_name} ${user.last_name}`;
                $uibModalInstance.close($scope.partner);
              },
              function (error) {
                growl.error(_t('app.admin.plans.new.unable_to_save_this_user_check_that_there_isnt_an_already_a_user_with_the_same_name'));
                console.error(error);
              }
            );
          };
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });
      // once the form was validated successfully ...
      return modalInstance.result.then(function (partner) {
        $scope.partners.push(partner);
      });
    };

    /**
     * Ask for confirmation then delete the specified user
     * @param memberId {number} identifier of the user to delete
     */
    $scope.deleteMember = function (memberId) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.members.confirmation_required'),
                msg: $sce.trustAsHtml(_t('app.admin.members.confirm_delete_member') + '<br/><br/>' + _t('app.admin.members.this_may_take_a_while_please_wait'))
              };
            }
          }
        },
        function () { // cancel confirmed
          Member.delete(
            { id: memberId },
            function () {
              $scope.members = _.filter($scope.members, function (m) { return m.id !== memberId; });
              return growl.success(_t('app.admin.members.member_successfully_deleted'));
            },
            function (error) {
              growl.error(_t('app.admin.members.unable_to_delete_the_member'));
              console.error(error);
            }
          );
        }
      );
    };

    $scope.onDeletedChild = function (memberId, childId) {
      $scope.members = $scope.members.map(function (member) {
        if (member.id === memberId) {
          member.children = _.filter(member.children, function (c) { return c.id !== childId; });
          return member;
        }
        return member;
      });
    };

    $scope.onUpdatedChild = function (memberId, child) {
      $scope.members = $scope.members.map(function (member) {
        if (member.id === memberId) {
          member.children = member.children.map(function (c) {
            if (c.id === child.id) {
              return child;
            }
            return c;
          });
          return member;
        }
        return member;
      });
    };

    /**
     * Ask for confirmation then delete the specified administrator
     * @param admins {Array} full list of administrators
     * @param admin {Object} administrator to delete
     */
    $scope.destroyAdmin = function (admins, admin) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.members.confirmation_required'),
                msg: $sce.trustAsHtml(_t('app.admin.members.do_you_really_want_to_delete_this_administrator_this_cannot_be_undone') + '<br/><br/>' + _t('app.admin.members.this_may_take_a_while_please_wait'))
              };
            }
          }
        },
        function () { // cancel confirmed
          Admin.delete(
            { id: admin.id },
            function () {
              admins.splice(findItemIdxById(admins, admin.id), 1);
              return growl.success(_t('app.admin.members.administrator_successfully_deleted'));
            },
            function (error) {
              growl.error(_t('app.admin.members.unable_to_delete_the_administrator'));
              console.error(error);
            }
          );
        }
      );
    };

    /**
     * Ask for confirmation then delete the specified partner
     * @param partners {Array} full list of partners
     * @param partner {Object} partner to delete
     */
    $scope.destroyPartner = function (partners, partner) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.members.confirmation_required'),
                msg: $sce.trustAsHtml(_t('app.admin.members.delete_this_partner') + '<br/><br/>' + _t('app.admin.members.this_may_take_a_while_please_wait'))
              };
            }
          }
        },
        function () { // cancel confirmed
          User.delete(
            { id: partner.id },
            function () {
              partners.splice(findItemIdxById(partners, partner.id), 1);
              return growl.success(_t('app.admin.members.partner_successfully_deleted'));
            },
            function (error) {
              growl.error(_t('app.admin.members.unable_to_delete_the_partner'));
              console.error(error);
            }
          );
        }
      );
    };

    /**
     * Ask for confirmation then delete the specified manager
     * @param managers {Array} full list of managers
     * @param manager {Object} manager to delete
     */
    $scope.destroyManager = function (managers, manager) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.members.confirmation_required'),
                msg: $sce.trustAsHtml(_t('app.admin.members.delete_this_manager') + '<br/><br/>' + _t('app.admin.members.this_may_take_a_while_please_wait'))
              };
            }
          }
        },
        function () { // cancel confirmed
          User.delete(
            { id: manager.id },
            function () {
              managers.splice(findItemIdxById(managers, manager.id), 1);
              return growl.success(_t('app.admin.members.manager_successfully_deleted'));
            },
            function (error) {
              growl.error(_t('app.admin.members.unable_to_delete_the_manager'));
              console.error(error);
            }
          );
        }
      );
    };

    /**
     * Callback for the 'load more' button.
     * Will load the next results of the current search, if any
     */
    $scope.showNextMembers = function () {
      $scope.member.page += 1;
      return memberSearch(true);
    };

    /**
     * Callback when the search field content changes: reload the search results
     */
    $scope.updateTextSearch = function () {
      if (searchTimeout) clearTimeout(searchTimeout);
      searchTimeout = setTimeout(function () {
        resetSearchMember();
        memberSearch();
      }, 300);
    };

    /**
     * Callback when the member filter changes: reload the search results
     */
    $scope.updateMemberFilter = function () {
      resetSearchMember();
      memberSearch();
    };

    /**
     * Callback to alert the admin that the export request was acknowledged and is
     * processing right now.
     */
    $scope.alertExport = function (type) {
      Export.status({ category: 'users', type }).then(function (res) {
        if (!res.data.exists) {
          return growl.success(_t('app.admin.members.export_is_running_you_ll_be_notified_when_its_ready'));
        }
      });
    };

    /**
     * Set up the feature-tour for the admin/members page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupMembersTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('members');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.members.welcome.title'),
        content: _t('app.admin.tour.members.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.members-management .members-list',
        stepId: 'list',
        order: 1,
        title: _t('app.admin.tour.members.list.title'),
        content: _t('app.admin.tour.members.list.content'),
        placement: 'top'
      });
      uitour.createStep({
        selector: '.members-management .search-members',
        stepId: 'search',
        order: 2,
        title: _t('app.admin.tour.members.search.title'),
        content: _t('app.admin.tour.members.search.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.members-management .filter-members',
        stepId: 'filter',
        order: 3,
        title: _t('app.admin.tour.members.filter.title'),
        content: _t('app.admin.tour.members.filter.content'),
        placement: 'bottom'
      });
      if ($scope.members.length > 0) {
        uitour.createStep({
          selector: '.members-management .members-list .member-actions',
          stepId: 'actions',
          order: 4,
          title: _t('app.admin.tour.members.actions.title'),
          content: _t('app.admin.tour.members.actions.content'),
          placement: 'left'
        });
      }
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: '.members-management .exports-buttons',
          stepId: 'exports',
          order: 5,
          title: _t('app.admin.tour.members.exports.title'),
          content: _t('app.admin.tour.members.exports.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.heading .import-members',
          stepId: 'import',
          order: 6,
          title: _t('app.admin.tour.members.import.title'),
          content: _t('app.admin.tour.members.import.content'),
          placement: 'left'
        });
      }
      uitour.createStep({
        selector: '.members-management .admins-tab',
        stepId: 'admins',
        order: 7,
        title: _t('app.admin.tour.members.admins.title'),
        content: _t('app.admin.tour.members.admins.content'),
        placement: 'bottom'
      });
      if (AuthService.isAuthorized('admin')) {
        uitour.createStep({
          selector: '.members-management .groups-tab',
          stepId: 'groups',
          order: 8,
          title: _t('app.admin.tour.members.groups.title'),
          content: _t('app.admin.tour.members.groups.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.members-management .labels-tab',
          stepId: 'labels',
          order: 9,
          title: _t('app.admin.tour.members.labels.title'),
          content: _t('app.admin.tour.members.labels.content'),
          placement: 'bottom'
        });
        uitour.createStep({
          selector: '.members-management .sso-tab',
          stepId: 'sso',
          order: 10,
          title: _t('app.admin.tour.members.sso.title'),
          content: _t('app.admin.tour.members.sso.content'),
          placement: 'bottom',
          popupClass: 'shift-left-50'
        });
      }
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 11,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on step change, change the active tab if needed
      uitour.on('stepChanged', function (nextStep) {
        if (nextStep.stepId === 'list' || nextStep.stepId === 'import') {
          $scope.tabs.active = 0;
          $scope.tabs.sub = 0;
        }
        if (nextStep.stepId === 'admins') {
          $scope.tabs.active = 0;
          $scope.tabs.sub = 1;
        }
        if (nextStep.stepId === 'groups') {
          $scope.tabs.active = 1;
        }
        if (nextStep.stepId === 'labels') {
          $scope.tabs.active = 2;
        }
        if (nextStep.stepId === 'sso') {
          $scope.tabs.active = 3;
        }
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile_attributes.tours.indexOf('members') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'members' }, function (res) {
            $scope.currentUser.profile_attributes.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile_attributes.tours.indexOf('members') < 0) {
        uitour.start();
      }
    };

    /**
     * Callback triggered in case of error
     */
    $scope.onError = (message) => {
      growl.error(message);
    };

    /**
     * Callback triggered in case of success
     */
    $scope.onSuccess = (message) => {
      growl.success(message);
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      if (!membersPromise[0] || (membersPromise[0].maxMembers <= $scope.members.length)) {
        return $scope.member.noMore = true;
      }
    };

    /**
     * Will temporize the search query to prevent overloading the API
     */
    let searchTimeout = null;

    /**
     * Iterate through the provided array and return the index of the requested item
     * @param items {Array} full list of users with the 'admin' role
     * @param id {Number} id of the item to retrieve in the list
     * @returns {Number} index of the requested item, in the provided array
     */
    const findItemIdxById = function (items, id) {
      return (items.map(function (item) { return item.id; })).indexOf(id);
    };

    /**
     * Reinitialize the context of the search to display new results set
     */
    const resetSearchMember = function () {
      $scope.member.noMore = false;
      $scope.member.page = 1;
    };

    /**
     * Run a search query with the current parameters set ($scope.member[searchText,order,page])
     * and affect or append the result in $scope.members, depending on the concat parameter
     * @param [concat] {boolean} if true, the result will be appended to $scope.members instead of being replaced
     */
    const memberSearch = function (concat) {
      Member.list({
        query: {
          search: $scope.member.searchText,
          order_by: $scope.member.order,
          filter: $scope.member.memberFilter,
          page: $scope.member.page,
          size: USERS_PER_PAGE
        }
      }, function (members) {
        if (concat) {
          $scope.members = $scope.members.concat(members);
        } else {
          $scope.members = members;
        }

        if (!members[0] || (members[0].maxMembers <= $scope.members.length)) {
          return $scope.member.noMore = true;
        }
      });
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the member edition page
 */
Application.Controllers.controller('EditMemberController', ['$scope', '$state', '$transition$', 'Member', 'Training', 'dialogs', 'growl', 'Group', 'Subscription', 'CSRF', 'memberPromise', 'tagsPromise', '$uibModal', 'Plan', '$filter', '_t', 'walletPromise', 'transactionsPromise', 'activeProviderPromise', 'Wallet', 'settingsPromise', 'SupportingDocumentType',
  function ($scope, $state, $transition$, Member, Training, dialogs, growl, Group, Subscription, CSRF, memberPromise, tagsPromise, $uibModal, Plan, $filter, _t, walletPromise, transactionsPromise, activeProviderPromise, Wallet, settingsPromise, SupportingDocumentType) {
  /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = `/api/members/${$transition$.params().id}`;

    // Form action on the above URL
    $scope.method = 'patch';

    // List of tags joinable with user
    $scope.tags = tagsPromise;

    // The user to edit
    $scope.user = cleanUser(memberPromise);

    // Should the password be modified?
    $scope.password = { change: false };

    // is the phone number required in _member_form?
    $scope.phoneRequired = (settingsPromise.phone_required === 'true');

    // is the address required in _member_form?
    $scope.addressRequired = (settingsPromise.address_required === 'true');

    // is the gender number required in _member_form?
    $scope.genderRequired = (settingsPromise.gender_required === 'true');

    // is the birthday required in _member_form?
    $scope.birthdayRequired = (settingsPromise.birthday_required === 'true');

    // is user validation required
    $scope.enableUserValidationRequired = (settingsPromise.user_validation_required === 'true');

    // the user subscription
    if (($scope.user.subscribed_plan != null) && ($scope.user.subscription != null)) {
      $scope.subscription = $scope.user.subscription;
    } else {
      Plan.query({ group_id: $scope.user.group_id }, function (plans) {
        $scope.plans = plans;
        return Array.from($scope.plans).map(function (plan) {
          return (plan.nameToDisplay = $filter('humanReadablePlanName')(plan));
        });
      });
    }

    // Available trainings list
    $scope.trainings = [];

    // Profiles types (student/standard/...)
    $scope.groups = [];

    // the user wallet
    $scope.wallet = walletPromise;

    // user wallet transactions
    $scope.transactions = transactionsPromise;

    // used in wallet partial template to identify parent view
    $scope.view = 'member_edit';

    // current active authentication provider
    $scope.activeProvider = activeProviderPromise;

    // modal dialog to extend the current subscription for free
    $scope.isOpenFreeExtendModal = false;

    // modal dialog to renew the current subscription
    $scope.isOpenRenewModal = false;

    // modal dialog to take a new subscription
    $scope.isOpenSubscribeModal = false;

    // modal dialog to change the user's role
    $scope.isOpenChangeRoleModal = false;

    // modal dialog to cancel the current subscription
    $scope.isOpenCancelModal = false;

    /**
     * Open a modal dialog asking for confirmation to change the role of the given user
     * @returns {*}
     */
    $scope.changeUserRole = function () {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: '/admin/members/change_role_modal.html',
        size: 'lg',
        resolve: {
          user () { return $scope.user; }
        },
        controller: ['$scope', '$uibModalInstance', 'Member', 'user', '_t', function ($scope, $uibModalInstance, Member, user, _t) {
          $scope.user = user;

          $scope.role = user.role;

          $scope.roles = [
            { key: 'admin', label: _t('app.admin.members_edit.admin') },
            { key: 'manager', label: _t('app.admin.members_edit.manager'), notAnOption: (user.role === 'admin') },
            { key: 'member', label: _t('app.admin.members_edit.member'), notAnOption: (user.role === 'admin' || user.role === 'manager') }
          ];

          $scope.ok = function () {
            Member.updateRole(
              { id: $scope.user.id },
              { role: $scope.role },
              function (_res) {
                growl.success(_t('app.admin.members_edit.role_changed', { OLD: _t(`app.admin.members_edit.${user.role}`), NEW: _t(`app.admin.members_edit.${$scope.role}`) }));
                return $uibModalInstance.close(_res);
              },
              function (error) {
                growl.error(_t('app.admin.members_edit.error_while_changing_role'));
                console.error(error);
              }
            );
          };

          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      });
      // once the form was validated successfully ...
      return modalInstance.result.then(function (user) {
        // remove the user for the old list add to the new
      });
    };

    /**
     * Opens/closes the modal dialog to freely extend the subscription
     */
    $scope.toggleFreeExtendModal = () => {
      setTimeout(() => {
        $scope.isOpenFreeExtendModal = !$scope.isOpenFreeExtendModal;
        $scope.$apply();
      }, 50);
    };

    /**
     * Opens/closes the modal dialog to renew the subscription (with payment)
     */
    $scope.toggleRenewModal = () => {
      setTimeout(() => {
        $scope.isOpenRenewModal = !$scope.isOpenRenewModal;
        $scope.$apply();
      }, 50);
    };

    /**
     * Opens/closes the modal dialog to cancel the current running subscription
     */
    $scope.toggleCancelModal = () => {
      setTimeout(() => {
        $scope.isOpenCancelModal = !$scope.isOpenCancelModal;
        $scope.$apply();
      }, 50);
    };

    /**
     * Opens/closes the modal dialog to renew the subscription (with payment)
     */
    $scope.toggleSubscribeModal = () => {
      setTimeout(() => {
        $scope.isOpenSubscribeModal = !$scope.isOpenSubscribeModal;
        $scope.$apply();
      }, 50);
    };

    /**
     * Opens/closes the modal dialog to change the user's role
     */
    $scope.toggleChangeRoleModal = () => {
      setTimeout(() => {
        $scope.isOpenChangeRoleModal = !$scope.isOpenChangeRoleModal;
        $scope.$apply();
      }, 0);
    };

    /**
     * Callback triggered if the subscription was successfully extended
     */
    $scope.onExtendSuccess = (message, newExpirationDate) => {
      growl.success(message);
      $scope.subscription.expired_at = newExpirationDate;
    };

    /**
     * Callback triggered when the subscription was successfully canceled
     */
    $scope.onCancelSuccess = (message) => {
      growl.success(message);
      $scope.user.subscribed_plan = null;
      $scope.user.subscription = null;
      $scope.subscription = null;
    };

    /**
     * Callback triggered if a new subscription was successfully taken
     */
    $scope.onSubscribeSuccess = (message, newSubscription) => {
      growl.success(message);
      $scope.subscription = newSubscription;
    };

    /**
     * Callback triggered if validate member was successfully taken
     */
    $scope.onValidateMemberSuccess = (_user, message) => {
      growl.success(message);
      setTimeout(() => {
        $scope.user = _user;
        $scope.user.statistic_profile_attributes.birthday = moment(_user.statistic_profile_attributes.birthday).toDate();
        $scope.$apply();
      }, 50);
    };

    /**
     * Callback triggered in case of error
     */
    $scope.onError = (message) => {
      console.error(message);
      growl.error(message);
    };

    /**
     * Callback triggered when the user was successfully updated
     */
    $scope.onUserSuccess = () => {
      growl.success(_t('app.admin.members_edit.update_success'));
      $state.go('app.admin.members');
    };

    /**
     * Callback triggered in case of success
     */
    $scope.onSuccess = (message) => {
      growl.success(message);
    };

    $scope.createWalletCreditModal = function (user, wallet) {
      const modalInstance = $uibModal.open({
        animation: true,
        templateUrl: '/wallet/credit_modal.html',
        controller: ['$scope', '$uibModalInstance', 'Wallet', function ($scope, $uibModalInstance, Wallet) {
        // default: do not generate a refund invoice
          $scope.generate_avoir = false;

          // optional description shown on the refund invoice
          $scope.description = '';

          // default configuration for the avoir date selector widget
          $scope.datePicker = {
            format: Fablab.uibDateFormat,
            opened: false,
            options: {
              startingDay: Fablab.weekStartingDay
            }
          };

          /**
           * Callback to open/close the date picker
           */
          $scope.toggleDatePicker = function ($event) {
            $event.preventDefault();
            $event.stopPropagation();
            return $scope.datePicker.opened = !$scope.datePicker.opened;
          };

          /**
           * Modal dialog validation callback
           */
          $scope.ok = function () {
            Wallet.credit(
              { id: wallet.id },
              {
                amount: $scope.amount,
                avoir: $scope.generate_avoir,
                avoir_description: $scope.description
              },
              function (_wallet) {
                growl.success(_t('app.shared.wallet.wallet_credit_successfully'));
                return $uibModalInstance.close(_wallet);
              },
              function (error) {
                growl.error(_t('app.shared.wallet.a_problem_occurred_for_wallet_credit'));
                console.error(error);
              }
            );
          };

          /**
           * Modal dialog cancellation callback
           */
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }
        ]
      });
      // once the form was validated successfully...
      return modalInstance.result.then(function (wallet) {
        $scope.wallet = wallet;
        return Wallet.transactions({ id: wallet.id }, function (transactions) { $scope.transactions = transactions; });
      });
    };

    /**
     * To use as callback in Array.prototype.filter to get only enabled plans
     */
    $scope.filterDisabledPlans = function (plan) { return !plan.disabled; };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      CSRF.setMetaTags();

      // the user subscription
      if (($scope.user.subscribed_plan != null) && ($scope.user.subscription != null)) {
        $scope.subscription = $scope.user.subscription;
      } else {
        Plan.query({ group_id: $scope.user.group_id }, function (plans) {
          $scope.plans = plans;
          return Array.from($scope.plans).map(function (plan) {
            return (plan.nameToDisplay = `${plan.base_name} - ${plan.interval}`);
          });
        });
      }

      SupportingDocumentType.query({ group_id: $scope.user.group_id }, function (supportingDocumentTypes) {
        $scope.hasProofOfIdentityTypes = supportingDocumentTypes.length > 0;
      });

      // Using the MembersController
      return new MembersController($scope, $state, Group, Training);
    };

    // prepare the user for the react-hook-form
    function cleanUser (user) {
      delete user.$promise;
      delete user.$resolved;
      return user;
    }

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the member's creation page (admin view)
 */
Application.Controllers.controller('NewMemberController', ['$scope', '$state', 'Member', 'Training', 'Group', 'CSRF', 'settingsPromise', 'growl', '_t',
  function ($scope, $state, Member, Training, Group, CSRF, settingsPromise, growl, _t) {
    CSRF.setMetaTags();

    /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = '/api/members';

    // Form action on the above URL
    $scope.method = 'post';

    // Should the password be set manually or generated?
    $scope.password = { change: false };

    // is the phone number required in _member_form?
    $scope.phoneRequired = (settingsPromise.phone_required === 'true');

    // is the address required to sign-up?
    $scope.addressRequired = (settingsPromise.address_required === 'true');

    // is the gender number required in _member_form?
    $scope.genderRequired = (settingsPromise.gender_required === 'true');

    // is the birthday required in _member_form?
    $scope.birthdayRequired = (settingsPromise.birthday_required === 'true');

    // Default member's profile parameters
    $scope.user = {
      plan_interval: '',
      is_allow_contact: false,
      invoicing_profile_attributes: {},
      statistic_profile_attributes: {}
    };

    // Callback when the admin check/uncheck the box telling that the new user is an organization.
    // Disable or enable the organization fields in the form, accordingly
    $scope.toggleOrganization = function () {
      if ($scope.user.organization) {
        if (!$scope.user.invoicing_profile_attributes) { $scope.user.invoicing_profile_attributes = {}; }
        $scope.user.invoicing_profile_attributes.organization_attributes = {};
      } else {
        $scope.user.invoicing_profile_attributes.organization_attributes = undefined;
      }
    };

    /**
     * Callback triggered when the user was successfully updated
     */
    $scope.onUserSuccess = () => {
      growl.success(_t('app.admin.members_new.create_success'));
      $state.go('app.admin.members');
    };

    /**
     * Callback triggered in case of error
     */
    $scope.onError = (message) => {
      console.error(message);
      growl.error(message);
    };

    // Using the MembersController
    return new MembersController($scope, $state, Group, Training);
  }
]);

/**
 * Controller used in the member's import page: import from CSV (admin view)
 */
Application.Controllers.controller('ImportMembersController', ['$scope', '$state', 'Group', 'Training', 'CSRF', 'tags', 'growl',
  function ($scope, $state, Group, Training, CSRF, tags, growl) {
    CSRF.setMetaTags();

    /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = '/api/imports/members';

    // Form action on the above URL
    $scope.method = 'post';

    // List of all tags
    $scope.tags = tags;

    /*
     * Callback run after the form was submitted
     * @param content {*} The result provided by the server, may be an Import object, or an error message
     */
    $scope.onImportResult = function (content) {
      if (content.id) {
        $state.go('app.admin.members_import_result', { id: content.id });
      } else {
        growl.error(JSON.stringify(content));
      }
    };

    // Using the MembersController
    return new MembersController($scope, $state, Group, Training);
  }
]);

/**
 * Controller used in the member's import results page (admin view)
 */
Application.Controllers.controller('ImportMembersResultController', ['$scope', '$state', 'Import', 'importItem',
  function ($scope, $state, Import, importItem) {
    /* PUBLIC SCOPE */

    // Current import as saved in database
    $scope.import = importItem;

    // Current import results
    $scope.results = null;

    /**
     * Changes the view of the admin to the members import page
     */
    $scope.cancel = function () { $state.go('app.admin.members_import'); };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      $scope.results = JSON.parse($scope.import.results);
      if (!$scope.results) {
        setTimeout(function () {
          Import.get({ id: $scope.import.id }, function (data) {
            $scope.import = data;
            initialize();
          });
        }, 5000);
      }
    };

    // !!! MUST BE CALLED AT THE END of the controller
    initialize();
  }
]);

/**
 * Controller used in the admin creation page (admin view)
 */
Application.Controllers.controller('NewAdminController', ['$state', '$scope', 'Admin', 'growl', '_t', 'settingsPromise', 'groupsPromise',
  function ($state, $scope, Admin, growl, _t, settingsPromise, groupsPromise) {
  // default admin profile
    let getGender;
    $scope.admin = {
      statistic_profile_attributes: {
        gender: true
      },
      profile_attributes: {},
      invoicing_profile_attributes: {}
    };

    // Default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      opened: false,
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    // is the phone number required in _admin_form?
    $scope.phoneRequired = (settingsPromise.phone_required === 'true');

    // is the address required in _admin_form?
    $scope.addressRequired = (settingsPromise.address_required === 'true');

    // is the gender number required in _admin_form?
    $scope.genderRequired = (settingsPromise.gender_required === 'true');

    // is the birthday required in _admin_form?
    $scope.birthdayRequired = (settingsPromise.birthday_required === 'true');

    // all available groups
    $scope.groups = groupsPromise;

    /**
   * Shows the birthday datepicker
   */
    $scope.openDatePicker = function () { $scope.datePicker.opened = true; };

    /**
   * Send the new admin, currently stored in $scope.admin, to the server for database saving
   */
    $scope.saveAdmin = function () {
      Admin.save(
        {},
        { admin: $scope.admin },
        function () {
          growl.success(_t('app.admin.admins_new.administrator_successfully_created_he_will_receive_his_connection_directives_by_email', { GENDER: getGender($scope.admin) }));
          return $state.go('app.admin.members');
        }
        , function (error) {
          growl.error(_t('app.admin.admins_new.failed_to_create_admin') + JSON.stringify(error.data ? error.data : error));
          console.error(error);
        }
      );
    };

    /* PRIVATE SCOPE */

    /**
   * Return an enumerable meaningful string for the gender of the provider user
   * @param user {Object} Database user record
   * @return {string} 'male' or 'female'
   */
    return getGender = function (user) {
      if (user.statistic_profile_attributes) {
        if (user.statistic_profile_attributes.gender) { return 'male'; } else { return 'female'; }
      } else { return 'other'; }
    };
  }

]);

/**
 * Controller used in the manager's creation page (admin view)
 */
Application.Controllers.controller('NewManagerController', ['$state', '$scope', 'User', 'groupsPromise', 'tagsPromise', 'growl', '_t', 'settingsPromise',
  function ($state, $scope, User, groupsPromise, tagsPromise, growl, _t, settingsPromise) {
  // default admin profile
    $scope.manager = {
      statistic_profile_attributes: {
        gender: true
      },
      profile_attributes: {},
      invoicing_profile_attributes: {}
    };

    // Default parameters for AngularUI-Bootstrap datepicker
    $scope.datePicker = {
      format: Fablab.uibDateFormat,
      opened: false,
      options: {
        startingDay: Fablab.weekStartingDay
      }
    };

    // is the phone number required in _admin_form?
    $scope.phoneRequired = (settingsPromise.phone_required === 'true');

    // is the address required in _admin_form?
    $scope.addressRequired = (settingsPromise.address_required === 'true');

    // is the gender number required in _admin_form?
    $scope.genderRequired = (settingsPromise.gender_required === 'true');

    // is the birthday required in _admin_form?
    $scope.birthdayRequired = (settingsPromise.birthday_required === 'true');

    // list of all groups
    $scope.groups = groupsPromise.filter(function (g) { return !g.disabled; });

    // list of all tags
    $scope.tags = tagsPromise;

    /**
   * Shows the birthday datepicker
   */
    $scope.openDatePicker = function () { $scope.datePicker.opened = true; };

    /**
   * Send the new manager, currently stored in $scope.manager, to the server for database saving
   */
    $scope.saveManager = function () {
      User.save(
        {},
        { manager: $scope.manager },
        function () {
          growl.success(_t('app.admin.manager_new.manager_successfully_created', { GENDER: getGender($scope.manager) }));
          return $state.go('app.admin.members');
        }
        , function (error) {
          growl.error(_t('app.admin.manager_new.failed_to_create_manager') + JSON.stringify(error.data ? error.data : error));
          console.error(error);
        }
      );
    };

    /* PRIVATE SCOPE */

    /**
   * Return an enumerable meaningful string for the gender of the provider user
   * @param user {Object} Database user record
   * @return {string} 'male' or 'female'
   */
    const getGender = function (user) {
      if (user.statistic_profile_attributes) {
        if (user.statistic_profile_attributes.gender) { return 'male'; } else { return 'female'; }
      } else { return 'other'; }
    };
  }

]);

/* eslint-disable
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/**
 * Navigation controller. List the links availables in the left navigation pane and their icon.
 */
Application.Controllers.controller('MainNavController', ['$scope', 'settingsPromise', function ($scope, settingsPromise) {
  // Common links (public application)
  $scope.navLinks = [
    {
      state: 'app.public.home',
      linkText: 'app.public.common.home',
      linkIcon: 'home',
      class: 'home-link'
    },
    { class: 'menu-spacer' },
    $scope.$root.modules.publicAgenda && {
      state: 'app.public.calendar',
      linkText: 'app.public.common.public_calendar',
      linkIcon: 'calendar',
      class: 'public-calendar-link'
    },
    $scope.$root.modules.machines && {
      state: 'app.public.machines_list',
      linkText: 'app.public.common.reserve_a_machine',
      linkIcon: 'cogs',
      class: 'reserve-machine-link'
    },
    $scope.$root.modules.trainings && {
      state: 'app.public.trainings_list',
      linkText: 'app.public.common.trainings_registrations',
      linkIcon: 'graduation-cap',
      class: 'reserve-training-link'
    },
    $scope.$root.modules.spaces && {
      state: 'app.public.spaces_list',
      linkText: 'app.public.common.reserve_a_space',
      linkIcon: 'rocket',
      class: 'reserve-space-link'
    },
    {
      state: 'app.public.events_list',
      linkText: 'app.public.common.events_registrations',
      linkIcon: 'tags',
      class: 'reserve-event-link'
    },
    { class: 'menu-spacer' },
    {
      state: 'app.public.projects_list',
      linkText: 'app.public.common.projects_gallery',
      linkIcon: 'th',
      class: 'projects-gallery-link'
    },
    $scope.$root.modules.plans && { class: 'menu-spacer' },
    $scope.$root.modules.plans && {
      state: 'app.public.plans',
      linkText: 'app.public.common.subscriptions',
      linkIcon: 'credit-card',
      class: 'plans-link'
    }
  ].filter(Boolean);

  Fablab.adminNavLinks = Fablab.adminNavLinks || [];
  $scope.adminNavLinks = [
    {
      state: 'app.admin.calendar',
      linkText: 'app.public.common.manage_the_calendar',
      linkIcon: 'calendar',
      authorizedRoles: ['admin', 'manager']
    },
    $scope.$root.modules.machines && {
      state: 'app.public.machines_list',
      linkText: 'app.public.common.manage_the_machines',
      linkIcon: 'cogs',
      authorizedRoles: ['admin', 'manager']
    },
    $scope.$root.modules.trainings && {
      state: 'app.admin.trainings',
      linkText: 'app.public.common.trainings_monitoring',
      linkIcon: 'graduation-cap',
      authorizedRoles: ['admin', 'manager']
    },
    $scope.$root.modules.spaces && {
      state: 'app.public.spaces_list',
      linkText: 'app.public.common.manage_the_spaces',
      linkIcon: 'rocket'
    },
    {
      state: 'app.admin.events',
      linkText: 'app.public.common.manage_the_events',
      linkIcon: 'tags',
      authorizedRoles: ['admin', 'manager']
    },
    { class: 'menu-spacer' },
    {
      state: 'app.admin.members',
      linkText: 'app.public.common.manage_the_users',
      linkIcon: 'users',
      authorizedRoles: ['admin', 'manager']
    },
    {
      state: 'app.admin.pricing',
      linkText: 'app.public.common.subscriptions_and_prices',
      linkIcon: 'money',
      authorizedRoles: ['admin']
    },
    {
      state: 'app.admin.invoices',
      linkText: 'app.public.common.manage_the_invoices',
      linkIcon: 'file-pdf-o',
      authorizedRoles: ['admin', 'manager']
    },
    $scope.$root.modules.statistics && {
      state: 'app.admin.statistics',
      linkText: 'app.public.common.statistics',
      linkIcon: 'bar-chart-o',
      authorizedRoles: ['admin']
    },
    {
      class: 'menu-spacer',
      authorizedRoles: ['admin']
    },
    {
      state: 'app.admin.settings',
      linkText: 'app.public.common.customization',
      linkIcon: 'gear',
      authorizedRoles: ['admin']
    },
    {
      state: 'app.admin.projects',
      linkText: 'app.public.common.projects',
      linkIcon: 'tasks',
      authorizedRoles: ['admin']
    },
    {
      state: 'app.admin.open_api_clients',
      linkText: 'app.public.common.open_api_clients',
      linkIcon: 'cloud',
      authorizedRoles: ['admin']
    }
  ].filter(Boolean).concat(Fablab.adminNavLinks);

  /**
   * Returns the current state of the public registration setting (allowed/blocked).
   */
  $scope.registrationEnabled = function () {
    return settingsPromise.public_registrations === 'true';
  };
}
]);

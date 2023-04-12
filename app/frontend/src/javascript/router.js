angular.module('application.router', ['ui.router'])
  .config(['$stateProvider', '$urlRouterProvider', '$locationProvider', function ($stateProvider, $urlRouterProvider, $locationProvider) {
    $locationProvider.hashPrefix('!');
    $urlRouterProvider.otherwise('/');

    // abstract root parents states
    // these states controls the access rights to the various routes inherited from them
    $stateProvider
      .state('app', {
        abstract: true,
        views: {
          header: {
            templateUrl: '/shared/header.html.erb',
            controller: 'HeaderController'
          },
          leftnav: {
            templateUrl: '/shared/leftnav.html',
            controller: 'MainNavController'
          },
          cookies: {
            templateUrl: '/shared/cookies.html',
            controller: 'CookiesController'
          },
          main: {}
        },
        resolve: {
          logoFile: ['CustomAsset', function (CustomAsset) { return CustomAsset.get({ name: 'logo-file' }).$promise; }],
          logoBlackFile: ['CustomAsset', function (CustomAsset) { return CustomAsset.get({ name: 'logo-black-file' }).$promise; }],
          sharedTranslations: ['Translations', function (Translations) { return Translations.query(['app.shared', 'app.public.common']).$promise; }],
          modulesPromise: ['Setting', function (Setting) { return Setting.query({ names: "['machines_module', 'spaces_module', 'plans_module', 'invoicing_module', 'wallet_module', 'statistics_module', 'trainings_module', 'public_agenda_module', 'store_module']" }).$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['public_registrations', 'store_hidden']" }).$promise; }]
        },
        onEnter: ['$rootScope', 'logoFile', 'logoBlackFile', 'modulesPromise', 'CSRF', function ($rootScope, logoFile, logoBlackFile, modulesPromise, CSRF) {
          // Retrieve Anti-CSRF tokens from cookies
          CSRF.setMetaTags();
          // Application logo
          $rootScope.logo = logoFile.custom_asset;
          $rootScope.logoBlack = logoBlackFile.custom_asset;
          $rootScope.modules = {
            machines: (modulesPromise.machines_module === 'true'),
            spaces: (modulesPromise.spaces_module === 'true'),
            plans: (modulesPromise.plans_module === 'true'),
            trainings: (modulesPromise.trainings_module === 'true'),
            store: (modulesPromise.store_module === 'true'),
            invoicing: (modulesPromise.invoicing_module === 'true'),
            wallet: (modulesPromise.wallet_module === 'true'),
            publicAgenda: (modulesPromise.public_agenda_module === 'true'),
            statistics: (modulesPromise.statistics_module === 'true')
          };
        }]
      })
      .state('app.public', {
        abstract: true,
        resolve: {
          publicTranslations: ['Translations', function (Translations) { return Translations.query(['app.public']).$promise; }]
        }
      })
      .state('app.logged', {
        abstract: true,
        data: {
          authorizedRoles: ['member', 'admin', 'manager']
        },
        resolve: {
          currentUser: ['Auth', function (Auth) { return Auth.currentUser(); }],
          loggedTranslations: ['Translations', function (Translations) { return Translations.query(['app.logged']).$promise; }]
        },
        onEnter: ['$state', '$timeout', 'currentUser', '$rootScope', function ($state, $timeout, currentUser, $rootScope) {
          $rootScope.currentUser = currentUser;
        }]
      })
      .state('app.admin', {
        abstract: true,
        data: {
          authorizedRoles: ['admin', 'manager']
        },
        resolve: {
          currentUser: ['Auth', function (Auth) { return Auth.currentUser(); }],
          adminTranslations: ['Translations', function (Translations) { return Translations.query(['app.admin']).$promise; }]
        },
        onEnter: ['$state', '$timeout', 'currentUser', '$rootScope', function ($state, $timeout, currentUser, $rootScope) {
          $rootScope.currentUser = currentUser;
        }]
      })

      // main pages
      .state('app.public.about', {
        url: '/about',
        views: {
          'content@': {
            templateUrl: '/shared/about.html',
            controller: 'AboutController'
          }
        }
      })
      .state('app.public.home', {
        url: '/?reset_password_token',
        views: {
          'main@': {
            templateUrl: '/home.html',
            controller: 'HomeController'
          }
        },
        resolve: {
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['home_content', 'home_blogpost', 'spaces_module', 'feature_tour_display']" }).$promise; }]
        }
      })
      .state('app.public.privacy', {
        url: '/privacy-policy',
        views: {
          'content@': {
            templateUrl: '/shared/privacy.html',
            controller: 'PrivacyController'
          }
        }
      })

      // profile completion (SSO import passage point)
      .state('app.logged.profileCompletion', {
        url: '/profile_completion',
        views: {
          'main@': {
            templateUrl: '/profile/complete.html',
            controller: 'CompleteProfileController'
          }
        },
        resolve: {
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['fablab_name', 'name_genre', 'phone_required', 'address_required']" }).$promise; }],
          activeProviderPromise: ['AuthProvider', function (AuthProvider) { return AuthProvider.active().$promise; }],
          groupsPromise: ['Group', function (Group) { return Group.query().$promise; }],
          cguFile: ['CustomAsset', function (CustomAsset) { return CustomAsset.get({ name: 'cgu-file' }).$promise; }],
          memberPromise: ['Member', 'currentUser', function (Member, currentUser) { return Member.get({ id: currentUser.id }).$promise; }]
        }
      })

      // dashboard
      .state('app.logged.dashboard', {
        abstract: true,
        url: '/dashboard',
        resolve: {
          memberPromise: ['Member', 'currentUser', function (Member, currentUser) { return Member.get({ id: currentUser.id }).$promise; }],
          trainingsPromise: ['Training', function (Training) { return Training.query().$promise; }],
          proofOfIdentityTypesPromise: ['SupportingDocumentType', 'currentUser', function (SupportingDocumentType, currentUser) { return SupportingDocumentType.query({ group_id: currentUser.group_id }).$promise; }]
        }
      })
      .state('app.logged.dashboard.profile', {
        url: '/profile',
        views: {
          'main@': {
            templateUrl: '/dashboard/profile.html',
            controller: 'DashboardController'
          }
        }
      })
      .state('app.logged.dashboard.settings', {
        url: '/settings',
        views: {
          'main@': {
            templateUrl: '/dashboard/settings.html',
            controller: 'EditProfileController'
          }
        },
        resolve: {
          groups: ['Group', function (Group) { return Group.query().$promise; }],
          activeProviderPromise: ['AuthProvider', function (AuthProvider) { return AuthProvider.active().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['phone_required', 'address_required']" }).$promise; }]
        }
      })
      .state('app.logged.dashboard.supporting_document_files', {
        url: '/supporting_document_files',
        views: {
          'main@': {
            templateUrl: '/dashboard/supporting_document_files.html',
            controller: 'DashboardController'
          }
        }
      })
      .state('app.logged.dashboard.projects', {
        url: '/projects',
        views: {
          'main@': {
            templateUrl: '/dashboard/projects.html',
            controller: 'DashboardController'
          }
        }
      })
      .state('app.logged.dashboard.trainings', {
        url: '/trainings',
        views: {
          'main@': {
            templateUrl: '/dashboard/trainings.html',
            controller: 'DashboardController'
          }
        }
      })
      .state('app.logged.dashboard.reservations_dashboard', {
        url: '/reservations',
        views: {
          'main@': {
            templateUrl: '/dashboard/reservations.html',
            controller: 'DashboardController'
          }
        }
      })
      .state('app.logged.dashboard.events', {
        url: '/events',
        views: {
          'main@': {
            templateUrl: '/dashboard/events.html',
            controller: 'DashboardController'
          }
        }
      })
      .state('app.logged.dashboard.invoices', {
        url: '/invoices',
        views: {
          'main@': {
            templateUrl: '/dashboard/invoices.html',
            controller: 'DashboardController'
          }
        }
      })
      .state('app.logged.dashboard.payment_schedules', {
        url: '/payment_schedules',
        views: {
          'main@': {
            templateUrl: '/dashboard/payment_schedules.html',
            controller: 'DashboardController'
          }
        }
      })
      .state('app.logged.dashboard.orders', {
        url: '/orders',
        views: {
          'main@': {
            templateUrl: '/dashboard/orders.html',
            controller: 'DashboardController'
          }
        }
      })
      .state('app.logged.dashboard.order_show', {
        url: '/orders/:id',
        views: {
          'main@': {
            templateUrl: '/orders/show.html',
            controller: 'ShowOrdersController'
          }
        }
      })
      .state('app.logged.dashboard.wallet', {
        url: '/wallet',
        abstract: !Fablab.walletModule,
        views: {
          'main@': {
            templateUrl: '/dashboard/wallet.html',
            controller: 'WalletController'
          }
        },
        resolve: {
          walletPromise: ['Wallet', 'currentUser', function (Wallet, currentUser) { return Wallet.getWalletByUser({ user_id: currentUser.id }).$promise; }],
          transactionsPromise: ['Wallet', 'walletPromise', function (Wallet, walletPromise) { return Wallet.transactions({ id: walletPromise.id }).$promise; }]
        }
      })

      // members
      .state('app.logged.members_show', {
        url: '/members/:id',
        views: {
          'main@': {
            templateUrl: '/members/show.html',
            controller: 'ShowProfileController'
          }
        },
        resolve: {
          memberPromise: ['$transition$', 'Member', function ($transition$, Member) { return Member.get({ id: $transition$.params().id }).$promise; }]
        }
      })
      .state('app.logged.members', {
        url: '/members',
        views: {
          'main@': {
            templateUrl: '/members/index.html',
            controller: 'MembersController'
          }
        },
        resolve: {
          membersPromise: ['Member', function (Member) { return Member.query({ requested_attributes: '[profile]', page: 1, size: 10 }).$promise; }]
        }
      })

      // projects
      .state('app.public.projects_list', {
        url: '/projects?q&page&theme_id&component_id&machine_id&from&whole_network&status_id',
        reloadOnSearch: false,
        views: {
          'main@': {
            templateUrl: '/projects/index.html',
            controller: 'ProjectsController'
          }
        },
        resolve: {
          themesPromise: ['Theme', function (Theme) { return Theme.query().$promise; }],
          componentsPromise: ['Component', function (Component) { return Component.query().$promise; }],
          machinesPromise: ['Machine', function (Machine) { return Machine.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['openlab_app_id', 'openlab_default']" }).$promise; }],
          openLabActive: ['Setting', function (Setting) { return Setting.isPresent({ name: 'openlab_app_secret' }).$promise; }]
        }
      })
      .state('app.logged.projects_new', {
        url: '/projects/new',
        views: {
          'main@': {
            templateUrl: '/projects/new.html',
            controller: 'NewProjectController'
          }
        },
        resolve: {
          allowedExtensions: ['Setting', function (Setting) { return Setting.get({ name: 'allowed_cad_extensions' }).$promise; }]
        }
      })
      .state('app.public.projects_show', {
        url: '/projects/:id',
        views: {
          'main@': {
            templateUrl: '/projects/show.html',
            controller: 'ShowProjectController'
          }
        },
        resolve: {
          projectPromise: ['$transition$', 'Project', function ($transition$, Project) { return Project.get({ id: $transition$.params().id }).$promise; }],
          shortnamePromise: ['Setting', function (Setting) { return Setting.get({ name: 'disqus_shortname' }).$promise; }]
        }
      })
      .state('app.logged.projects_edit', {
        url: '/projects/:id/edit',
        views: {
          'main@': {
            templateUrl: '/projects/edit.html',
            controller: 'EditProjectController'
          }
        },
        resolve: {
          projectPromise: ['$transition$', 'Project', function ($transition$, Project) { return Project.get({ id: $transition$.params().id }).$promise; }],
          allowedExtensions: ['Setting', function (Setting) { return Setting.get({ name: 'allowed_cad_extensions' }).$promise; }]
        }
      })

      // machines
      .state('app.public.machines_list', {
        url: '/machines',
        abstract: !Fablab.machinesModule,
        views: {
          'main@': {
            templateUrl: '/machines/index.html',
            controller: 'MachinesController'
          }
        },
        resolve: {
          machinesPromise: ['Machine', function (Machine) { return Machine.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['feature_tour_display', 'user_validation_required', 'user_validation_required_list']" }).$promise; }]
        }
      })
      .state('app.admin.machines_list', {
        url: '/admin/machines',
        abstract: !Fablab.machinesModule,
        views: {
          'main@': {
            templateUrl: '/admin/machines/index.html',
            controller: 'AdminMachinesController'
          }
        },
        resolve: {
          machinesPromise: ['Machine', function (Machine) { return Machine.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['feature_tour_display', 'user_validation_required', 'user_validation_required_list']" }).$promise; }]
        }
      })
      .state('app.admin.machines_new', {
        url: '/machines/new',
        abstract: !Fablab.machinesModule,
        views: {
          'main@': {
            templateUrl: '/machines/new.html',
            controller: 'NewMachineController'
          }
        }
      })
      .state('app.public.machines_show', {
        url: '/machines/:id',
        abstract: !Fablab.machinesModule,
        views: {
          'main@': {
            templateUrl: '/machines/show.html',
            controller: 'ShowMachineController'
          }
        },
        resolve: {
          machinePromise: ['Machine', '$transition$', function (Machine, $transition$) { return Machine.get({ id: $transition$.params().id }).$promise; }]
        }
      })
      .state('app.logged.machines_reserve', {
        url: '/machines/:id/reserve',
        abstract: !Fablab.machinesModule,
        views: {
          'main@': {
            templateUrl: '/machines/reserve.html',
            controller: 'ReserveMachineController'
          }
        },
        resolve: {
          plansPromise: ['Plan', function (Plan) { return Plan.query().$promise; }],
          groupsPromise: ['Group', function (Group) { return Group.query().$promise; }],
          machinePromise: ['Machine', '$transition$', function (Machine, $transition$) { return Machine.get({ id: $transition$.params().id }).$promise; }],
          settingsPromise: ['Setting', function (Setting) {
            return Setting.query({
              names: "['machine_explications_alert', 'booking_window_start',  'booking_window_end',  'booking_move_enable', " +
                     "'booking_move_delay', 'booking_cancel_enable',  'booking_cancel_delay', 'subscription_explications_alert', " +
                     "'online_payment_module', 'payment_gateway', 'overlapping_categories', 'user_validation_required', 'user_validation_required_list']"
            }).$promise;
          }]
        }
      })
      .state('app.admin.machines_edit', {
        url: '/machines/:id/edit',
        abstract: !Fablab.machinesModule,
        views: {
          'main@': {
            templateUrl: '/machines/edit.html',
            controller: 'EditMachineController'
          }
        },
        resolve: {
          machinePromise: ['Machine', '$transition$', function (Machine, $transition$) { return Machine.get({ id: $transition$.params().id }).$promise; }],
          machineCategoriesPromise: ['MachineCategory', function (MachineCategory) { return MachineCategory.query().$promise; }]
        }
      })

      // spaces
      .state('app.public.spaces_list', {
        url: '/spaces',
        abstract: !Fablab.spacesModule,
        views: {
          'main@': {
            templateUrl: '/spaces/index.html',
            controller: 'SpacesController'
          }
        },
        resolve: {
          spacesPromise: ['Space', function (Space) { return Space.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['feature_tour_display']" }).$promise; }]
        }
      })
      .state('app.admin.space_new', {
        url: '/spaces/new',
        abstract: !Fablab.spacesModule,
        views: {
          'main@': {
            templateUrl: '/spaces/new.html',
            controller: 'NewSpaceController'
          }
        }
      })
      .state('app.public.space_show', {
        url: '/spaces/:id',
        abstract: !Fablab.spacesModule,
        views: {
          'main@': {
            templateUrl: '/spaces/show.html',
            controller: 'ShowSpaceController'
          }
        },
        resolve: {
          spacePromise: ['Space', '$transition$', function (Space, $transition$) { return Space.get({ id: $transition$.params().id }).$promise; }]
        }
      })
      .state('app.admin.space_edit', {
        url: '/spaces/:id/edit',
        abstract: !Fablab.spacesModule,
        views: {
          'main@': {
            templateUrl: '/spaces/edit.html',
            controller: 'EditSpaceController'
          }
        },
        resolve: {
          spacePromise: ['Space', '$transition$', function (Space, $transition$) { return Space.get({ id: $transition$.params().id }).$promise; }]
        }
      })
      .state('app.logged.space_reserve', {
        url: '/spaces/:id/reserve',
        abstract: !Fablab.spacesModule,
        views: {
          'main@': {
            templateUrl: '/spaces/reserve.html',
            controller: 'ReserveSpaceController'
          }
        },
        resolve: {
          spacePromise: ['Space', '$transition$', function (Space, $transition$) { return Space.get({ id: $transition$.params().id }).$promise; }],
          plansPromise: ['Plan', function (Plan) { return Plan.query().$promise; }],
          groupsPromise: ['Group', function (Group) { return Group.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) {
            return Setting.query({
              names: "['booking_window_start', 'booking_window_end', 'booking_move_enable',  'booking_move_delay', " +
                     "'booking_cancel_enable', 'booking_cancel_delay', 'subscription_explications_alert',  " +
                     "'space_explications_alert', 'online_payment_module', 'payment_gateway', 'overlapping_categories', " +
                     "'user_validation_required', 'user_validation_required_list']"
            }).$promise;
          }]
        }
      })

      // trainings
      .state('app.public.trainings_list', {
        url: '/trainings',
        abstract: !Fablab.trainingsModule,
        views: {
          'main@': {
            templateUrl: '/trainings/index.html',
            controller: 'TrainingsController'
          }
        },
        resolve: {
          trainingsPromise: ['Training', function (Training) { return Training.query({ public_page: true, disabled: false }).$promise; }]
        }
      })
      .state('app.public.training_show', {
        url: '/trainings/:id',
        abstract: !Fablab.trainingsModule,
        views: {
          'main@': {
            templateUrl: '/trainings/show.html',
            controller: 'ShowTrainingController'
          }
        },
        resolve: {
          trainingPromise: ['Training', '$transition$', function (Training, $transition$) { return Training.get({ id: $transition$.params().id }).$promise; }]
        }
      })
      .state('app.logged.trainings_reserve', {
        url: '/trainings/:id/reserve',
        abstract: !Fablab.trainingsModule,
        views: {
          'main@': {
            templateUrl: '/trainings/reserve.html',
            controller: 'ReserveTrainingController'
          }
        },
        resolve: {
          explicationAlertPromise: ['Setting', function (Setting) { return Setting.get({ name: 'training_explications_alert' }).$promise; }],
          plansPromise: ['Plan', function (Plan) { return Plan.query().$promise; }],
          groupsPromise: ['Group', function (Group) { return Group.query().$promise; }],
          trainingPromise: ['Training', '$transition$', function (Training, $transition$) {
            if ($transition$.params().id !== 'all') { return Training.get({ id: $transition$.params().id }).$promise; }
          }],
          settingsPromise: ['Setting', function (Setting) {
            return Setting.query({
              names: "['booking_window_start', 'booking_window_end', 'booking_move_enable', 'booking_move_delay', " +
                     "'booking_cancel_enable', 'booking_cancel_delay', 'subscription_explications_alert', " +
                     "'training_explications_alert', 'training_information_message', 'online_payment_module', " +
                     "'payment_gateway', 'overlapping_categories', 'user_validation_required', 'user_validation_required_list']"
            }).$promise;
          }]
        }
      })
      // notifications
      .state('app.logged.notifications', {
        url: '/notifications',
        views: {
          'main@': {
            templateUrl: '/notifications/index.html',
            controller: 'NotificationsController'
          }
        }
      })

      // pricing
      .state('app.public.plans', {
        url: '/plans',
        abstract: !Fablab.plansModule,
        views: {
          'main@': {
            templateUrl: '/plans/index.html',
            controller: 'PlansIndexController'
          }
        },
        resolve: {
          subscriptionExplicationsPromise: ['Setting', function (Setting) { return Setting.get({ name: 'subscription_explications_alert' }).$promise; }],
          groupsPromise: ['Group', function (Group) { return Group.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['online_payment_module', 'payment_gateway', 'overlapping_categories', 'user_validation_required', 'user_validation_required_list']" }).$promise; }]
        }
      })

      // events
      .state('app.public.events_list', {
        url: '/events',
        views: {
          'main@': {
            templateUrl: '/events/index.html',
            controller: 'EventsController'
          }
        },
        resolve: {
          categoriesPromise: ['Category', function (Category) { return Category.query().$promise; }],
          themesPromise: ['EventTheme', function (EventTheme) { return EventTheme.query().$promise; }],
          ageRangesPromise: ['AgeRange', function (AgeRange) { return AgeRange.query().$promise; }]
        }
      })
      .state('app.public.events_show', {
        url: '/events/:id',
        views: {
          'main@': {
            templateUrl: '/events/show.html',
            controller: 'ShowEventController'
          }
        },
        resolve: {
          eventPromise: ['Event', '$transition$', function (Event, $transition$) { return Event.get({ id: $transition$.params().id }).$promise; }],
          priceCategoriesPromise: ['PriceCategory', function (PriceCategory) { return PriceCategory.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['booking_move_enable', 'booking_move_delay', 'booking_cancel_enable', 'booking_cancel_delay', 'event_explications_alert', 'online_payment_module', 'user_validation_required', 'user_validation_required_list']" }).$promise; }]
        }
      })

      // global calendar (trainings, machines and events)
      .state('app.public.calendar', {
        url: '/calendar',
        abstract: !Fablab.publicAgendaModule,
        views: {
          'main@': {
            templateUrl: '/calendar/calendar.html',
            controller: 'CalendarController'
          }
        },
        resolve: {
          bookingWindowStart: ['Setting', function (Setting) { return Setting.get({ name: 'booking_window_start' }).$promise; }],
          bookingWindowEnd: ['Setting', function (Setting) { return Setting.get({ name: 'booking_window_end' }).$promise; }],
          trainingsPromise: ['Training', function (Training) { return Training.query().$promise; }],
          machinesPromise: ['Machine', function (Machine) { return Machine.query().$promise; }],
          spacesPromise: ['Space', function (Space) { return Space.query().$promise; }],
          iCalendarPromise: ['ICalendar', function (ICalendar) { return ICalendar.query().$promise; }],
          machineCategoriesPromise: ['MachineCategory', function (MachineCategory) { return MachineCategory.query().$promise; }]
        }
      })

      // store
      .state('app.public.store', {
        url: '/store/:categoryTypeUrl/:category?{machines:string}{keywords:string}{is_active:string}{is_available:string}{page:string}{sort:string}',
        abstract: !Fablab.storeModule,
        views: {
          'main@': {
            templateUrl: '/store/index.html',
            controller: 'StoreController'
          }
        },
        params: {
          categoryTypeUrl: { raw: true, type: 'path', value: null, squash: true },
          category: { type: 'path', raw: true, value: null, squash: true },
          machines: { array: true, dynamic: true, type: 'query', raw: true },
          keywords: { dynamic: true, type: 'query' },
          is_active: { dynamic: true, type: 'query', value: 'true', squash: true },
          is_available: { dynamic: true, type: 'query', value: 'false', squash: true },
          page: { dynamic: true, type: 'query', value: '1', squash: true },
          sort: { dynamic: true, type: 'query' },
          authorizedRoles: { dynamic: true, raw: true }
        }
      })

      // show product
      .state('app.public.product_show', {
        url: '/store/p/:slug',
        abstract: !Fablab.storeModule,
        views: {
          'main@': {
            templateUrl: '/products/show.html',
            controller: 'ShowProductController'
          }
        }
      })

      // cart
      .state('app.public.store_cart', {
        url: '/store/cart',
        abstract: !Fablab.storeModule,
        views: {
          'main@': {
            templateUrl: '/cart/index.html',
            controller: 'CartController'
          }
        }
      })

      // --- namespace /admin/... ---
      // calendar
      .state('app.admin.calendar', {
        url: '/admin/calendar',
        views: {
          'main@': {
            templateUrl: '/admin/calendar/calendar.html',
            controller: 'AdminCalendarController'
          }
        },
        resolve: {
          bookingWindowStart: ['Setting', function (Setting) { return Setting.get({ name: 'booking_window_start' }).$promise; }],
          bookingWindowEnd: ['Setting', function (Setting) { return Setting.get({ name: 'booking_window_end' }).$promise; }],
          machinesPromise: ['Machine', function (Machine) { return Machine.query().$promise; }],
          plansPromise: ['Plan', function (Plan) { return Plan.query().$promise; }],
          groupsPromise: ['Group', function (Group) { return Group.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['slot_duration', 'events_in_calendar', 'feature_tour_display']" }).$promise; }],
          trainingsPromise: ['Training', function (Training) { return Training.query().$promise; }],
          spacesPromise: ['Space', function (Space) { return Space.query().$promise; }],
          machineCategoriesPromise: ['MachineCategory', function (MachineCategory) { return MachineCategory.query().$promise; }]
        }
      })
      .state('app.admin.calendar.icalendar', {
        url: '/admin/calendar/icalendar',
        views: {
          'main@': {
            templateUrl: '/admin/calendar/icalendar.html',
            controller: 'AdminICalendarController'
          }
        },
        resolve: {
          iCalendars: ['ICalendar', function (ICalendar) { return ICalendar.query().$promise; }]
        }
      })

      // project's settings
      .state('app.admin.projects', {
        url: '/admin/projects',
        views: {
          'main@': {
            templateUrl: '/admin/projects/index.html',
            controller: 'AdminProjectsController'
          }
        },
        resolve: {
          componentsPromise: ['Component', function (Component) { return Component.query().$promise; }],
          licencesPromise: ['Licence', function (Licence) { return Licence.query().$promise; }],
          themesPromise: ['Theme', function (Theme) { return Theme.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) {
            return Setting.query({
              names: "['feature_tour_display', 'disqus_shortname', 'allowed_cad_extensions', " +
                     "'allowed_cad_mime_types', 'openlab_app_id', 'openlab_app_secret', 'openlab_default']"
            }).$promise;
          }]
        }
      })
      .state('app.admin.manage_abuses', {
        url: '/admin/abuses',
        views: {
          'main@': {
            templateUrl: '/admin/abuses/index.html',
            controller: 'AbusesController'
          }
        },
        resolve: {
          abusesPromise: ['Abuse', function (Abuse) { return Abuse.query().$promise; }]
        }
      })

      // trainings
      .state('app.admin.trainings', {
        url: '/admin/trainings',
        abstract: !Fablab.trainingsModule,
        views: {
          'main@': {
            templateUrl: '/admin/trainings/index.html',
            controller: 'TrainingsAdminController'
          }
        },
        resolve: {
          trainingsPromise: ['Training', function (Training) { return Training.query().$promise; }],
          machinesPromise: ['Machine', function (Machine) { return Machine.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['feature_tour_display', 'machines_module']" }).$promise; }]
        }
      })
      .state('app.admin.trainings_new', {
        url: '/admin/trainings/new',
        abstract: !Fablab.trainingsModule,
        views: {
          'main@': {
            templateUrl: '/admin/trainings/new.html',
            controller: 'NewTrainingController'
          }
        }
      })
      .state('app.admin.trainings_edit', {
        url: '/admin/trainings/:id/edit',
        abstract: !Fablab.trainingsModule,
        views: {
          'main@': {
            templateUrl: '/admin/trainings/edit.html',
            controller: 'EditTrainingController'
          }
        },
        resolve: {
          trainingPromise: ['Training', '$transition$', function (Training, $transition$) { return Training.get({ id: $transition$.params().id }).$promise; }]
        }
      })
      // events
      .state('app.admin.events', {
        url: '/admin/events',
        views: {
          'main@': {
            templateUrl: '/admin/events/index.html',
            controller: 'AdminEventsController'
          }
        },
        resolve: {
          eventsPromise: ['Event', function (Event) { return Event.query({ page: 1 }).$promise; }],
          categoriesPromise: ['Category', function (Category) { return Category.query().$promise; }],
          themesPromise: ['EventTheme', function (EventTheme) { return EventTheme.query().$promise; }],
          ageRangesPromise: ['AgeRange', function (AgeRange) { return AgeRange.query().$promise; }],
          priceCategoriesPromise: ['PriceCategory', function (PriceCategory) { return PriceCategory.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['feature_tour_display']" }).$promise; }]
        }
      })
      .state('app.admin.events_new', {
        url: '/admin/events/new',
        views: {
          'main@': {
            templateUrl: '/events/new.html',
            controller: 'NewEventController'
          }
        }
      })
      .state('app.admin.events_edit', {
        url: '/admin/events/:id/edit',
        views: {
          'main@': {
            templateUrl: '/events/edit.html',
            controller: 'EditEventController'
          }
        },
        resolve: {
          eventPromise: ['Event', '$transition$', function (Event, $transition$) { return Event.get({ id: $transition$.params().id }).$promise; }]
        }
      })
      .state('app.admin.event_reservations', {
        url: '/admin/events/:id/reservations',
        views: {
          'main@': {
            templateUrl: '/admin/events/reservations.html',
            controller: 'ShowEventReservationsController'
          }
        },
        resolve: {
          eventPromise: ['Event', '$transition$', function (Event, $transition$) { return Event.get({ id: $transition$.params().id }).$promise; }],
          reservationsPromise: ['Reservation', '$transition$', function (Reservation, $transition$) { return Reservation.query({ reservable_id: $transition$.params().id, reservable_type: 'Event' }).$promise; }]
        }
      })

      // pricing
      .state('app.admin.pricing', {
        url: '/admin/pricing',
        views: {
          'main@': {
            templateUrl: '/admin/pricing/index.html',
            controller: 'EditPricingController'
          }
        },
        resolve: {
          plans: ['Plan', function (Plan) { return Plan.query().$promise; }],
          groups: ['Group', function (Group) { return Group.query().$promise; }],
          trainingsPricingsPromise: ['TrainingsPricing', function (TrainingsPricing) { return TrainingsPricing.query().$promise; }],
          trainingsPromise: ['Training', function (Training) { return Training.query().$promise; }],
          machineCreditsPromise: ['Credit', function (Credit) { return Credit.query({ creditable_type: 'Machine' }).$promise; }],
          machinesPromise: ['Machine', function (Machine) { return Machine.query().$promise; }],
          trainingCreditsPromise: ['Credit', function (Credit) { return Credit.query({ creditable_type: 'Training' }).$promise; }],
          couponsPromise: ['Coupon', function (Coupon) { return Coupon.query({ page: 1, filter: 'all' }).$promise; }],
          spacesPromise: ['Space', function (Space) { return Space.query().$promise; }],
          spacesPricesPromise: ['Price', function (Price) { return Price.query({ priceable_type: 'Space', plan_id: 'null' }).$promise; }],
          spacesCreditsPromise: ['Credit', function (Credit) { return Credit.query({ creditable_type: 'Space' }).$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['feature_tour_display', 'slot_duration', 'user_validation_required', 'user_validation_required_list']" }).$promise; }],
          planCategories: ['PlanCategory', function (PlanCategory) { return PlanCategory.query().$promise; }]
        }
      })

      // plans
      .state('app.admin.plans', {
        abstract: true,
        resolve: {
          prices: ['Pricing', function (Pricing) { return Pricing.query().$promise; }],
          groups: ['Group', function (Group) { return Group.query().$promise; }],
          partners: ['User', function (User) { return User.query({ role: 'partner' }).$promise; }]
        }
      })
      .state('app.admin.plans.new', {
        url: '/admin/plans/new',
        views: {
          'main@': {
            templateUrl: '/admin/plans/new.html',
            controller: 'NewPlanController'
          }
        },
        resolve: {
          planCategories: ['PlanCategory', function (PlanCategory) { return PlanCategory.query().$promise; }]
        }
      })
      .state('app.admin.plans.edit', {
        url: '/admin/plans/:id/edit',
        views: {
          'main@': {
            templateUrl: '/admin/plans/edit.html',
            controller: 'EditPlanController'
          }
        },
        resolve: {
          spaces: ['Space', function (Space) { return Space.query().$promise; }],
          machines: ['Machine', function (Machine) { return Machine.query().$promise; }],
          plans: ['Plan', function (Plan) { return Plan.query().$promise; }],
          planPromise: ['Plan', '$transition$', function (Plan, $transition$) { return Plan.get({ id: $transition$.params().id }).$promise; }],
          planCategories: ['PlanCategory', function (PlanCategory) { return PlanCategory.query().$promise; }]
        }
      })
      // plan categories
      .state('app.admin.plan_categories', {
        url: '/admin/plan_categories',
        views: {
          'main@': {
            templateUrl: '/admin/plans/categories.html',
            controller: 'PlanCategoriesController'
          }
        }
      })

      // coupons
      .state('app.admin.coupons_new', {
        url: '/admin/coupons/new',
        views: {
          'main@': {
            templateUrl: '/admin/coupons/new.html',
            controller: 'NewCouponController'
          }
        }
      })
      .state('app.admin.coupons_edit', {
        url: '/admin/coupons/:id/edit',
        views: {
          'main@': {
            templateUrl: '/admin/coupons/edit.html',
            controller: 'EditCouponController'
          }
        },
        resolve: {
          couponPromise: ['Coupon', '$transition$', function (Coupon, $transition$) { return Coupon.get({ id: $transition$.params().id }).$promise; }]
        }
      })

      // show order
      .state('app.admin.order_show', {
        url: '/admin/store/orders/:id',
        abstract: !Fablab.storeModule,
        views: {
          'main@': {
            templateUrl: '/admin/orders/show.html',
            controller: 'AdminShowOrdersController'
          }
        }
      })

      // invoices
      .state('app.admin.invoices', {
        url: '/admin/invoices',
        views: {
          'main@': {
            templateUrl: '/admin/invoices/index.html',
            controller: 'InvoicesController'
          }
        },
        resolve: {
          settings: ['Setting', function (Setting) {
            return Setting.query({
              names: "['invoice_legals', 'invoice_text', 'invoice_VAT-rate', 'invoice_VAT-rate_Machine', " +
                     "'invoice_VAT-active', 'invoice_order-nb', 'invoice_code-value', " +
                     "'invoice_code-active', 'invoice_reference', 'invoice_logo', 'payment_gateway', 'payment_schedule_prefix', 'invoicing_module', " +
                     "'feature_tour_display', 'online_payment_module', 'stripe_public_key', 'stripe_currency', 'invoice_prefix', 'invoice_VAT-name']"
            }).$promise;
          }],
          stripeSecretKey: ['Setting', function (Setting) { return Setting.isPresent({ name: 'stripe_secret_key' }).$promise; }],
          onlinePaymentStatus: ['Payment', function (Payment) { return Payment.onlinePaymentStatus().$promise; }],
          invoices: ['Invoice', function (Invoice) {
            return Invoice.list({
              query: { number: '', customer: '', date: null, order_by: '-date', page: 1, size: 20 }
            }).$promise;
          }],
          closedPeriods: ['AccountingPeriod', function (AccountingPeriod) { return AccountingPeriod.query().$promise; }]
        }
      })

      // members
      .state('app.admin.members', {
        url: '/admin/members',
        views: {
          'main@': {
            templateUrl: '/admin/members/index.html',
            controller: 'AdminMembersController'
          },
          'groups@app.admin.members': {
            templateUrl: '/admin/groups/index.html',
            controller: 'GroupsController'
          },
          'tags@app.admin.members': {
            templateUrl: '/admin/tags/index.html',
            controller: 'TagsController'
          },
          'authentification@app.admin.members': {
            templateUrl: '/admin/authentications/index.html',
            controller: 'AuthentificationController'
          }
        },
        resolve: {
          membersPromise: ['Member', function (Member) { return Member.list({ query: { search: '', order_by: 'id', page: 1, size: 20 } }).$promise; }],
          adminsPromise: ['Admin', function (Admin) { return Admin.query().$promise; }],
          partnersPromise: ['User', function (User) { return User.query({ role: 'partner' }).$promise; }],
          managersPromise: ['User', function (User) { return User.query({ role: 'manager' }).$promise; }],
          groupsPromise: ['Group', function (Group) { return Group.query().$promise; }],
          tagsPromise: ['Tag', function (Tag) { return Tag.query().$promise; }],
          authProvidersPromise: ['AuthProvider', function (AuthProvider) { return AuthProvider.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['feature_tour_display', 'user_validation_required', 'show_username_in_admin_list']" }).$promise; }]
        }
      })
      .state('app.admin.members_new', {
        url: '/admin/members/new',
        views: {
          'main@': {
            templateUrl: '/admin/members/new.html',
            controller: 'NewMemberController'
          }
        },
        resolve: {
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['phone_required', 'address_required']" }).$promise; }]
        }
      })
      .state('app.admin.members_import', {
        url: '/admin/members/import',
        views: {
          'main@': {
            templateUrl: '/admin/members/import.html',
            controller: 'ImportMembersController'
          }
        },
        resolve: {
          tags: ['Tag', function (Tag) { return Tag.query().$promise; }]
        }
      })
      .state('app.admin.members_import_result', {
        url: '/admin/members/import/:id/results',
        views: {
          'main@': {
            templateUrl: '/admin/members/import_result.html',
            controller: 'ImportMembersResultController'
          }
        },
        resolve: {
          importItem: ['Import', '$transition$', function (Import, $transition$) { return Import.get({ id: $transition$.params().id }).$promise; }]
        }
      })
      .state('app.admin.members_edit', {
        url: '/admin/members/:id/edit',
        views: {
          'main@': {
            templateUrl: '/admin/members/edit.html',
            controller: 'EditMemberController'
          }
        },
        resolve: {
          memberPromise: ['Member', '$transition$', function (Member, $transition$) { return Member.get({ id: $transition$.params().id }).$promise; }],
          activeProviderPromise: ['AuthProvider', function (AuthProvider) { return AuthProvider.active().$promise; }],
          walletPromise: ['Wallet', '$transition$', function (Wallet, $transition$) { return Wallet.getWalletByUser({ user_id: $transition$.params().id }).$promise; }],
          transactionsPromise: ['Wallet', 'walletPromise', function (Wallet, walletPromise) { return Wallet.transactions({ id: walletPromise.id }).$promise; }],
          tagsPromise: ['Tag', function (Tag) { return Tag.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['phone_required', 'address_required', 'user_validation_required']" }).$promise; }]
        }
      })
      .state('app.admin.admins_new', {
        url: '/admin/admins/new',
        views: {
          'main@': {
            templateUrl: '/admin/admins/new.html',
            controller: 'NewAdminController'
          }
        },
        resolve: {
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['phone_required', 'address_required']" }).$promise; }],
          groupsPromise: ['Group', function (Group) { return Group.query({ disabled: false }).$promise; }]
        }
      })
      .state('app.admin.managers_new', {
        url: '/admin/managers/new',
        views: {
          'main@': {
            templateUrl: '/admin/managers/new.html',
            controller: 'NewManagerController'
          }
        },
        resolve: {
          groupsPromise: ['Group', function (Group) { return Group.query().$promise; }],
          tagsPromise: ['Tag', function (Tag) { return Tag.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['phone_required', 'address_required']" }).$promise; }]
        }
      })

      // authentication providers
      .state('app.admin.authentication_new', {
        url: '/admin/authentications/new',
        views: {
          'main@': {
            templateUrl: '/admin/authentications/new.html',
            controller: 'NewAuthenticationController'
          }
        }
      })
      .state('app.admin.authentication_edit', {
        url: '/admin/authentications/:id/edit',
        views: {
          'main@': {
            templateUrl: '/admin/authentications/edit.html',
            controller: 'EditAuthenticationController'
          }
        },
        resolve: {
          providerPromise: ['AuthProvider', '$transition$', function (AuthProvider, $transition$) { return AuthProvider.get({ id: $transition$.params().id }).$promise; }]
        }
      })

      // statistics
      .state('app.admin.statistics', {
        url: '/admin/statistics',
        abstract: !Fablab.statisticsModule,
        views: {
          'main@': {
            templateUrl: '/admin/statistics/index.html',
            controller: 'StatisticsController'
          }
        },
        resolve: {
          membersPromise: ['Member', function (Member) { return Member.mapping().$promise; }],
          statisticsPromise: ['Statistics', function (Statistics) { return Statistics.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['feature_tour_display']" }).$promise; }]
        }
      })
      .state('app.admin.stats_graphs', {
        url: '/admin/statistics/evolution',
        abstract: !Fablab.statisticsModule,
        views: {
          'main@': {
            templateUrl: '/admin/statistics/graphs.html',
            controller: 'GraphsController'
          }
        }
      })

      // configurations
      .state('app.admin.settings', {
        url: '/admin/settings',
        views: {
          'main@': {
            templateUrl: '/admin/settings/index.html',
            controller: 'SettingsController'
          }
        },
        resolve: {
          settingsPromise: ['Setting', function (Setting) {
            return Setting.query({
              names: "['twitter_name', 'about_title', 'about_body', 'tracking_id', 'facebook_app_id', 'email_from', " +
                     "'privacy_body', 'privacy_dpo', 'about_contacts', 'book_overlapping_slots', 'invoicing_module', " +
                     "'home_blogpost', 'machine_explications_alert', 'training_explications_alert', 'slot_duration', " +
                     "'training_information_message', 'subscription_explications_alert', 'event_explications_alert', " +
                     "'space_explications_alert', 'booking_window_start', 'booking_window_end', 'events_in_calendar', " +
                     "'booking_move_enable', 'booking_move_delay', 'booking_cancel_enable', 'feature_tour_display', " +
                     "'booking_cancel_delay', 'main_color', 'secondary_color', 'spaces_module', 'twitter_analytics', " +
                     "'fablab_name', 'name_genre', 'reminder_enable', 'plans_module', 'confirmation_required', " +
                     "'reminder_delay', 'visibility_yearly', 'visibility_others', 'wallet_module', 'trainings_module', " +
                     "'display_name_enable', 'machines_sort_by', 'fab_analytics', 'statistics_module', 'address_required', " +
                     "'link_name', 'home_content', 'home_css', 'phone_required', 'upcoming_events_shown', 'public_agenda_module'," +
                     "'renew_pack_threshold', 'pack_only_for_subscription', 'overlapping_categories', 'public_registrations'," +
                     "'extended_prices_in_same_day', 'recaptcha_site_key', 'recaptcha_secret_key', 'user_validation_required', " +
                     "'user_validation_required_list', 'machines_module', 'user_change_group', 'show_username_in_admin_list', " +
                     "'store_module', 'machine_reservation_deadline', 'training_reservation_deadline', 'event_reservation_deadline', " +
                     "'space_reservation_deadline']"
            }).$promise;
          }],
          privacyDraftsPromise: ['Setting', function (Setting) { return Setting.get({ name: 'privacy_draft', history: true }).$promise; }],
          cguFile: ['CustomAsset', function (CustomAsset) { return CustomAsset.get({ name: 'cgu-file' }).$promise; }],
          cgvFile: ['CustomAsset', function (CustomAsset) { return CustomAsset.get({ name: 'cgv-file' }).$promise; }],
          faviconFile: ['CustomAsset', function (CustomAsset) { return CustomAsset.get({ name: 'favicon-file' }).$promise; }],
          profileImageFile: ['CustomAsset', function (CustomAsset) { return CustomAsset.get({ name: 'profile-image-file' }).$promise; }]
        }
      })

      .state('app.admin.store', {
        abstract: true,
        url: '/admin/store'
      })

      .state('app.admin.store.settings', {
        url: '/settings',
        abstract: !Fablab.storeModule,
        data: {
          authorizedRoles: ['admin']
        },
        views: {
          'main@': {
            templateUrl: '/admin/store/index.html',
            controller: 'AdminStoreController'
          }
        }
      })

      .state('app.admin.store.products', {
        url: '/products?{categories:string}{machines:string}{keywords:string}{stock_type:string}{stock_from:string}{stock_to:string}{is_active:string}{page:string}{sort:string}',
        abstract: !Fablab.storeModule,
        views: {
          'main@': {
            templateUrl: '/admin/store/index.html',
            controller: 'AdminStoreController'
          }
        },
        params: {
          categories: { array: true, dynamic: true, type: 'query', raw: true },
          machines: { array: true, dynamic: true, type: 'query', raw: true },
          keywords: { dynamic: true, type: 'query' },
          stock_type: { dynamic: true, type: 'query', value: 'internal', squash: true },
          stock_from: { dynamic: true, type: 'query', value: '0', squash: true },
          stock_to: { dynamic: true, type: 'query', value: '0', squash: true },
          is_active: { dynamic: true, type: 'query', value: 'false', squash: true },
          page: { dynamic: true, type: 'query', value: '1', squash: true },
          sort: { dynamic: true, type: 'query' }
        }
      })

      .state('app.admin.store.products_new', {
        url: '/products/new',
        abstract: !Fablab.storeModule,
        views: {
          'main@': {
            templateUrl: '/admin/store/product_new.html',
            controller: 'AdminStoreProductController'
          }
        }
      })

      .state('app.admin.store.products_edit', {
        url: '/products/:id/edit',
        abstract: !Fablab.storeModule,
        views: {
          'main@': {
            templateUrl: '/admin/store/product_edit.html',
            controller: 'AdminStoreProductController'
          }
        }
      })

      .state('app.admin.store.categories', {
        url: '/categories',
        abstract: !Fablab.storeModule,
        views: {
          'main@': {
            templateUrl: '/admin/store/index.html',
            controller: 'AdminStoreController'
          }
        }
      })

      .state('app.admin.store.orders', {
        url: '/orders',
        abstract: !Fablab.storeModule,
        views: {
          'main@': {
            templateUrl: '/admin/store/index.html',
            controller: 'AdminStoreController'
          }
        }
      })

      // OpenAPI Clients
      .state('app.admin.open_api_clients', {
        url: '/open_api_clients',
        views: {
          'main@': {
            templateUrl: '/admin/open_api_clients/index.html.erb',
            controller: 'OpenAPIClientsController'
          }
        },
        resolve: {
          clientsPromise: ['OpenAPIClient', function (OpenAPIClient) { return OpenAPIClient.query().$promise; }],
          settingsPromise: ['Setting', function (Setting) { return Setting.query({ names: "['feature_tour_display']" }).$promise; }]
        }
      });
  }

  ]);

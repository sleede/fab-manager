'use strict';

/**
* The application file bootstraps the angular app by  initializing the main module and
* creating namespaces and moduled for controllers, filters, services, and directives.
*/

// eslint-disable-next-line no-var -- Application is a global variable.
var Application = Application || {};

Application.Components = angular.module('application.components', []);
Application.Services = angular.module('application.services', []);
Application.Controllers = angular.module('application.controllers', []);
Application.Filters = angular.module('application.filters', []);
Application.Directives = angular.module('application.directives', []);

angular.module('application', ['ngCookies', 'ngResource', 'ngSanitize', 'ui.router', 'ui.bootstrap',
  'ngUpload', 'duScroll', 'application.filters', 'application.services', 'application.directives',
  'frapontillo.bootstrap-switch', 'application.controllers', 'application.router', 'application.components',
  'ui.select', 'ui.calendar', 'angularMoment', 'Devise', 'angular-growl', 'xeditable',
  'checklist-model', 'unsavedChanges', 'angular-loading-bar', 'ngTouch',
  'angularUtils.directives.dirDisqus', 'summernote', 'elasticsearch', 'angular-medium-editor', 'naif.base64',
  'minicolors', 'pascalprecht.translate', 'ngFitText', 'ngAside', 'ngCapsLock', 'vcRecaptcha', 'ui.codemirror',
  'bm.uiTour'])
  .config(['$httpProvider', 'AuthProvider', 'growlProvider', 'unsavedWarningsConfigProvider', 'uibDatepickerPopupConfig', '$provide', '$translateProvider', 'TourConfigProvider', '$sceDelegateProvider',
    function ($httpProvider, AuthProvider, growlProvider, unsavedWarningsConfigProvider, uibDatepickerPopupConfig, $provide, $translateProvider, TourConfigProvider, $sceDelegateProvider) {
      // Google analytics
      // first we check the user acceptance
      const cookiesConsent = document.cookie.replace(/(?:(?:^|.*;\s*)fab-manager-cookies-consent\s*=\s*([^;]*).*$)|^.*$/, '$1');
      if (cookiesConsent === 'accept') {
        GTM.enableAnalytics(Fablab.trackingId);
      } else {
        // if the cookies were not explicitly accepted, delete them
        document.cookie = '_ga=; expires=Thu, 01 Jan 1970 00:00:00 GMT';
        document.cookie = '_gid=; expires=Thu, 01 Jan 1970 00:00:00 GMT';
      }

      // Custom messages for the date-picker widget
      uibDatepickerPopupConfig.closeText = Fablab.translations.app.shared.buttons.close;
      uibDatepickerPopupConfig.clearText = Fablab.translations.app.shared.buttons.clear;
      uibDatepickerPopupConfig.currentText = Fablab.translations.app.shared.buttons.today;

      // Custom messages for angular-unsavedChanges
      unsavedWarningsConfigProvider.navigateMessage = Fablab.translations.app.shared.messages.you_will_lose_any_unsaved_modification_if_you_quit_this_page;
      unsavedWarningsConfigProvider.reloadMessage = Fablab.translations.app.shared.messages.you_will_lose_any_unsaved_modification_if_you_reload_this_page;

      // Set how long the popup messages (growl) will remain
      growlProvider.globalTimeToLive(5000);

      // Configure the i18n module to load the partial translations from the given API URL
      $translateProvider.useLoader('$translatePartialLoader', {
        urlTemplate: '/api/translations/{lang}/{part}'
      });
      // Enable the cache to speed-up the loading times on already seen pages
      $translateProvider.useLoaderCache(true);
      // Secure i18n module against XSS attacks by escaping the output
      $translateProvider.useSanitizeValueStrategy('escapeParameters');
      // Use the MessageFormat interpolation by default (used for pluralization)
      $translateProvider.useMessageFormatInterpolation();
      // Set the language of the instance (from ruby configuration)
      $translateProvider.preferredLanguage(Fablab.locale);
      // End the tour when the user clicks the forward or back buttons of the browser
      TourConfigProvider.enableNavigationInterceptors();

      $sceDelegateProvider.resourceUrlWhitelist(['self']);
    }]).run(['$rootScope', '$transitions', '$log', 'Auth', 'amMoment', '$state', 'editableOptions',
    function ($rootScope, $transitions, $log, Auth, amMoment, $state, editableOptions) {
      // Angular-moment (date-time manipulations library)
      amMoment.changeLocale(Fablab.moment_locale);

      // Angular-xeditable (click-to-edit elements, used in admin backoffice)
      editableOptions.theme = 'bs3';

      // Alter the UI-Router's $state, registering into some information concerning the previous $state.
      // This is used to allow the user to navigate to the previous state
      $transitions.onSuccess({ }, function (trans) {
        $state.prevState = trans.$from().name;
        $state.prevParams = Object.fromEntries(
          Object.keys(trans.$from().params).map(k => {
            return [k, trans.$from().params[k].value()];
          })
        );

        const path = trans.router.stateService.href(trans.$to(), {}, { absolute: true });
        GTM.trackPage(path, trans.$to().name);
      });

      // Global function to allow the user to navigate to the previous screen (ie. $state).
      // If no previous $state were recorded, navigate to the home page
      $rootScope.backPrevLocation = function (event) {
        event.preventDefault();
        event.stopPropagation();
        if ($state.prevState === '') {
          $state.prevState = 'app.public.home';
        }
        $state.go($state.prevState, $state.prevParams);
      };

      // Configuration of the summernote editor (used in project edition)
      $rootScope.summernoteOpts = {
        lang: Fablab.summernote_locale,
        height: 200,
        toolbar: [
          ['style', ['style']],
          ['font', ['bold', 'italic', 'underline', 'clear']],
          ['color', ['color']],
          ['para', ['ul', 'ol']],
          ['table', ['table']],
          ['insert', ['link', 'picture', 'hr']],
          ['view', ['fullscreen', 'codeview']],
          ['group', ['video']],
          ['help', ['help']]
        ],
        styleTags: ['p', 'blockquote', 'pre', 'h4', 'h5', 'h6'],
        maximumImageFileSize: 4096
      };

      // Prevent the usage of the application for members with incomplete profiles: they will be redirected to
      // the 'profile completion' page. This is especially useful for user's accounts imported through SSO.
      $transitions.onStart({}, function (trans) {
        Auth.currentUser().then(function (currentUser) {
          if (currentUser.need_completion && trans.$to().name !== 'app.logged.profileCompletion') {
            $state.go('app.logged.profileCompletion');
          }
        }).catch(() => {
          // no one is logged, just ignore
        });
      });

      /**
       * This helper method builds and return an array containing every integers between
       * the provided start and end.
       * @param start {number}
       * @param end {number}
       * @return {Array} [start .. end]
       */
      $rootScope.intArray = function (start, end) {
        const arr = [];
        for (let i = start; i < end; i++) { arr.push(i); }
        return arr;
      };
    }]).constant('angularMomentConfig', {
    timezone: Fablab.timezone
  }).constant('moment', require('moment-timezone'));

angular.isUndefinedOrNull = function (val) {
  return angular.isUndefined(val) || val === null;
};

module.exports = { Application };

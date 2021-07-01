/* eslint-disable
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

Application.Controllers.controller('SettingsController', ['$scope', '$rootScope', '$filter', '$uibModal', 'dialogs', 'Setting', 'growl', 'settingsPromise', 'privacyDraftsPromise', 'cgvFile', 'cguFile', 'logoFile', 'logoBlackFile', 'faviconFile', 'profileImageFile', 'CSRF', '_t', 'Member', 'uiTourService',
  function ($scope, $rootScope, $filter, $uibModal, dialogs, Setting, growl, settingsPromise, privacyDraftsPromise, cgvFile, cguFile, logoFile, logoBlackFile, faviconFile, profileImageFile, CSRF, _t, Member, uiTourService) {
    /* PUBLIC SCOPE */

    // timepickers steps configuration
    $scope.timepicker = {
      hstep: 1,
      mstep: 15
    };

    // API URL where the upload forms will be posted
    $scope.actionUrl = {
      cgu: '/api/custom_assets',
      cgv: '/api/custom_assets',
      logo: '/api/custom_assets',
      logoBlack: '/api/custom_assets',
      favicon: '/api/custom_assets',
      profileImage: '/api/custom_assets'
    };

    // Form actions on the above URL
    $scope.methods = {
      cgu: 'post',
      cgv: 'post',
      logo: 'post',
      logoBlack: 'post',
      favicon: 'post',
      profileImage: 'post'
    };

    // Are we uploading the files currently (if so, display the loader)
    $scope.loader = {
      cgu: false,
      cgv: false
    };

    // default tab: general
    $scope.tabs = { active: 0 };

    // full history of privacy policy drafts
    $scope.privacyDraftsHistory = [];

    // all settings as retrieved from database
    $scope.allSettings = settingsPromise;

    // various configurable settings
    $scope.aboutTitleSetting = { name: 'about_title', value: settingsPromise.about_title };
    $scope.aboutBodySetting = { name: 'about_body', value: settingsPromise.about_body };
    $scope.privacyDpoSetting = { name: 'privacy_dpo', value: settingsPromise.privacy_dpo };
    $scope.aboutContactsSetting = { name: 'about_contacts', value: settingsPromise.about_contacts };
    $scope.homeBlogpostSetting = { name: 'home_blogpost', value: settingsPromise.home_blogpost };
    $scope.homeContent = { name: 'home_content', value: settingsPromise.home_content };
    $scope.homeCss = { name: 'home_css', value: settingsPromise.home_css };
    $scope.machineExplicationsAlert = { name: 'machine_explications_alert', value: settingsPromise.machine_explications_alert };
    $scope.trainingExplicationsAlert = { name: 'training_explications_alert', value: settingsPromise.training_explications_alert };
    $scope.trainingInformationMessage = { name: 'training_information_message', value: settingsPromise.training_information_message };
    $scope.subscriptionExplicationsAlert = { name: 'subscription_explications_alert', value: settingsPromise.subscription_explications_alert };
    $scope.eventExplicationsAlert = { name: 'event_explications_alert', value: settingsPromise.event_explications_alert };
    $scope.spaceExplicationsAlert = { name: 'space_explications_alert', value: settingsPromise.space_explications_alert };
    $scope.windowStart = { name: 'booking_window_start', value: settingsPromise.booking_window_start };
    $scope.windowEnd = { name: 'booking_window_end', value: settingsPromise.booking_window_end };
    $scope.mainColorSetting = { name: 'main_color', value: settingsPromise.main_color };
    $scope.secondColorSetting = { name: 'secondary_color', value: settingsPromise.secondary_color };
    $scope.nameGenre = { name: 'name_genre', value: settingsPromise.name_genre };
    $scope.cguFile = cguFile.custom_asset;
    $scope.cgvFile = cgvFile.custom_asset;
    $scope.customLogo = logoFile.custom_asset;
    $scope.customLogoBlack = logoBlackFile.custom_asset;
    $scope.customFavicon = faviconFile.custom_asset;
    $scope.profileImage = profileImageFile.custom_asset;

    // By default, we display the currently published privacy policy
    $scope.privacyPolicy = {
      version: null,
      bodyTemp: settingsPromise.privacy_body
    };

    // Extend the options for summernote editor, with special tools for home page
    $scope.summernoteOptsHomePage = angular.copy($rootScope.summernoteOpts);
    $scope.summernoteOptsHomePage.toolbar[5][1].push('nugget'); // toolbar -> insert -> nugget
    $scope.summernoteOptsHomePage.nugget = {
      label: '\uF12E',
      tooltip: _t('app.admin.settings.home_items'),
      list: [
        `<div id="news">${_t('app.admin.settings.item_news')}</div>`,
        `<div id="projects">${_t('app.admin.settings.item_projects')}</div>`,
        `<div id="twitter">${_t('app.admin.settings.item_twitter')}</div>`,
        `<div id="members">${_t('app.admin.settings.item_members')}</div>`,
        `<div id="events">${_t('app.admin.settings.item_events')}</div>`
      ]
    };
    $scope.summernoteOptsHomePage.height = 400;

    // codemirror editor
    $scope.codeMirrorEditor = null;

    // Options for codemirror editor, used for custom css
    $scope.codemirrorOpts = {
      matchBrackets: true,
      lineNumbers: true,
      mode: 'sass'
    };

    // Show or hide advanced settings
    $scope.advancedSettings = {
      open: false
    };

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

    /**
     * Callback to save the setting value to the database
     * @param setting {{value:*, name:string}} note that the value will be stringified
     */
    $scope.save = function (setting) {
      // trim empty html
      let value;
      if ((setting.value === '<br>') || (setting.value === '<p><br></p>')) {
        setting.value = '';
      }
      // convert dates to ISO format
      if (setting.value instanceof Date) {
        setting.value = setting.value.toISOString();
      }

      if (setting.value !== null) {
        value = setting.value.toString();
      } else {
        ({ value } = setting);
      }

      Setting.update(
        { name: setting.name },
        { value },
        function () { growl.success(_t('app.admin.settings.customization_of_SETTING_successfully_saved', { SETTING: _t(`app.admin.settings.${setting.name}`) })); },
        function (error) {
          if (error.status === 304) return;

          growl.error(_t('app.admin.settings.an_error_occurred_saving_the_setting'));
          console.log(error);
        }
      );
    };

    /**
     * The privacy policy has its own special save function because updating the policy must notify all users
     */
    $scope.savePrivacyPolicy = function () {
      // open modal
      const modalInstance = $uibModal.open({
        templateUrl: '/admin/settings/save_policy.html',
        controller: 'SavePolicyController',
        resolve: {
          saveCb () { return $scope.save; },
          privacyPolicy () { return $scope.privacyPolicy; }
        }
      });

      // once done, update the client data
      modalInstance.result.then(function (type) {
        Setting.get({ name: 'privacy_draft', history: true }, function (data) {
          // reset history
          $scope.privacyDraftsHistory = [];
          data.setting.history.forEach(function (draft) {
            $scope.privacyDraftsHistory.push({ id: draft.id, name: _t('app.admin.settings.privacy.draft_from_USER_DATE', { USER: draft.user.name, DATE: draft.created_at }), content: draft.value });
          });
          if (type === 'privacy_draft') {
            const orderedHistory = $filter('orderBy')(data.setting.history, 'created_at');
            const last = orderedHistory[orderedHistory.length - 1];
            if (last) {
              $scope.privacyPolicy.version = last.id;
            }
          } else {
            $scope.privacyPolicy.version = null;
          }
        });
      });
    };

    /**
     * For use with ngUpload (https://github.com/twilson63/ngUpload).
     * Intended to be the callback when the upload is done: Any raised error will be displayed in a growl
     * message. If everything goes fine, a growl success message is shown.
     * @param content {Object} JSON - The upload's result
     */
    $scope.submited = function (content) {
      if ((content.custom_asset == null)) {
        $scope.alerts = [];
        return angular.forEach(content, function (v) {
          angular.forEach(v, function (err) { growl.error(err); });
        });
      } else {
        growl.success(_t('app.admin.settings.file_successfully_updated'));
        if (content.custom_asset.name === 'cgu-file') {
          $scope.cguFile = content.custom_asset;
          $scope.methods.cgu = 'put';
          if (!($scope.actionUrl.cgu.indexOf('/cgu-file') > 0)) { $scope.actionUrl.cgu += '/cgu-file'; }
          return $scope.loader.cgu = false;
        } else if (content.custom_asset.name === 'cgv-file') {
          $scope.cgvFile = content.custom_asset;
          $scope.methods.cgv = 'put';
          if (!($scope.actionUrl.cgv.indexOf('/cgv-file') > 0)) { $scope.actionUrl.cgv += '/cgv-file'; }
          return $scope.loader.cgv = false;
        } else if (content.custom_asset.name === 'logo-file') {
          $scope.customLogo = content.custom_asset;
          $scope.methods.logo = 'put';
          if (!($scope.actionUrl.logo.indexOf('/logo-file') > 0)) { return $scope.actionUrl.logo += '/logo-file'; }
        } else if (content.custom_asset.name === 'logo-black-file') {
          $scope.customLogoBlack = content.custom_asset;
          $scope.methods.logoBlack = 'put';
          if (!($scope.actionUrl.logoBlack.indexOf('/logo-black-file') > 0)) { return $scope.actionUrl.logoBlack += '/logo-black-file'; }
        } else if (content.custom_asset.name === 'favicon-file') {
          $scope.customFavicon = content.custom_asset;
          $scope.methods.favicon = 'put';
          if (!($scope.actionUrl.favicon.indexOf('/favicon-file') > 0)) { return $scope.actionUrl.favicon += '/favicon-file'; }
        } else if (content.custom_asset.name === 'profile-image-file') {
          $scope.profileImage = content.custom_asset;
          $scope.methods.profileImage = 'put';
          if (!($scope.actionUrl.profileImage.indexOf('/profile-image-file') > 0)) { return $scope.actionUrl.profileImage += '/profile-image-file'; }
        }
      }
    };

    /**
     * @param target {String} 'cgu' | 'cgv'
     */
    $scope.addLoader = function (target) {
      $scope.loader[target] = true;
    };

    /**
     * Change the revision of the displayed privacy policy, from drafts history
     */
    $scope.handlePolicyRevisionChange = function () {
      if ($scope.privacyPolicy.version === null) {
        $scope.privacyPolicy.bodyTemp = settingsPromise.privacy_body;
        return;
      }
      for (const draft of $scope.privacyDraftsHistory) {
        if (draft.id === $scope.privacyPolicy.version) {
          $scope.privacyPolicy.bodyTemp = draft.content;
          break;
        }
      }
    };

    /**
     * Open a modal showing a sample of the collected data if FabAnalytics is enabled
     */
    $scope.analyticsModal = function () {
      $uibModal.open({
        templateUrl: '/admin/settings/analyticsModal.html',
        controller: 'AnalyticsModalController',
        size: 'lg',
        resolve: {
          analyticsData: ['FabAnalytics', function (FabAnalytics) { return FabAnalytics.data().$promise; }]
        }
      });
    };

    /**
     * Reset the home page to its initial state (factory value)
     */
    $scope.resetHomePage = function () {
      dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('app.admin.settings.confirmation_required'),
              msg: _t('app.admin.settings.confirm_reset_home_page')
            };
          }
        }
      }
      , function () { // confirmed
        Setting.reset({ name: 'home_content' }, function (data) {
          $scope.homeContent.value = data.value;
          growl.success(_t('app.admin.settings.home_content_reset'));
        });
      }
      );
    };

    /**
     * Callback triggered when the codemirror editor is loaded into the DOM
     * @param editor codemirror instance
     */
    $scope.codemirrorLoaded = function (editor) {
      $scope.codeMirrorEditor = editor;
    };

    /**
     * Setup the feature-tour for the admin/settings page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupSettingsTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('settings');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.settings.welcome.title'),
        content: _t('app.admin.tour.settings.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.admin-settings .general-page-tab',
        stepId: 'general',
        order: 1,
        title: _t('app.admin.tour.settings.general.title'),
        content: _t('app.admin.tour.settings.general.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.admin-settings .home-page-content h4',
        stepId: 'home',
        order: 2,
        title: _t('app.admin.tour.settings.home.title'),
        content: _t('app.admin.tour.settings.home.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.admin-settings .home-page-content .note-toolbar .note-insert div',
        stepId: 'components',
        order: 3,
        title: _t('app.admin.tour.settings.components.title'),
        content: _t('app.admin.tour.settings.components.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.admin-settings .home-page-content .note-toolbar .btn-codeview',
        stepId: 'codeview',
        order: 4,
        title: _t('app.admin.tour.settings.codeview.title'),
        content: _t('app.admin.tour.settings.codeview.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.admin-settings .reset-button',
        stepId: 'reset',
        order: 5,
        title: _t('app.admin.tour.settings.reset.title'),
        content: _t('app.admin.tour.settings.reset.content'),
        placement: 'left'
      });
      uitour.createStep({
        selector: '.admin-settings .home-page-style',
        stepId: 'css',
        order: 6,
        title: _t('app.admin.tour.settings.css.title'),
        content: _t('app.admin.tour.settings.css.content'),
        placement: 'top'
      });
      uitour.createStep({
        selector: '.admin-settings .about-page-tab',
        stepId: 'about',
        order: 7,
        title: _t('app.admin.tour.settings.about.title'),
        content: _t('app.admin.tour.settings.about.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.admin-settings .privacy-page-tab',
        stepId: 'privacy',
        order: 8,
        title: _t('app.admin.tour.settings.privacy.title'),
        content: _t('app.admin.tour.settings.privacy.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.admin-settings .history-select',
        stepId: 'draft',
        order: 9,
        title: _t('app.admin.tour.settings.draft.title'),
        content: _t('app.admin.tour.settings.draft.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: '.admin-settings .reservations-page-tab',
        stepId: 'reservations',
        order: 10,
        title: _t('app.admin.tour.settings.reservations.title'),
        content: _t('app.admin.tour.settings.reservations.content'),
        placement: 'bottom',
        popupClass: 'shift-left-50'
      });
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
        if (nextStep.stepId === 'general') { $scope.tabs.active = 0; }
        if (nextStep.stepId === 'home' || nextStep.stepId === 'css') { $scope.tabs.active = 1; }
        if (nextStep.stepId === 'about') { $scope.tabs.active = 2; }
        if (nextStep.stepId === 'privacy' || nextStep.stepId === 'draft') { $scope.tabs.active = 3; }
        if (nextStep.stepId === 'reservations') { $scope.tabs.active = 4; }
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('settings') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'settings' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if ($scope.allSettings.feature_tour_display !== 'manual' && $scope.currentUser.profile.tours.indexOf('settings') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // set the authenticity tokens in the forms
      CSRF.setMetaTags();

      // we prevent the admin from setting the closing time before the opening time
      $scope.$watch('windowEnd.value', function (newValue, oldValue, scope) {
        if ($scope.windowStart && moment($scope.windowStart.value).isAfter(newValue)) {
          return $scope.windowEnd.value = oldValue;
        }
      });

      // change form methods to PUT if items already exists
      if (cguFile.custom_asset) {
        $scope.methods.cgu = 'put';
        $scope.actionUrl.cgu += '/cgu-file';
      }
      if (cgvFile.custom_asset) {
        $scope.methods.cgv = 'put';
        $scope.actionUrl.cgv += '/cgv-file';
      }
      if (logoFile.custom_asset) {
        $scope.methods.logo = 'put';
        $scope.actionUrl.logo += '/logo-file';
      }
      if (logoBlackFile.custom_asset) {
        $scope.methods.logoBlack = 'put';
        $scope.actionUrl.logoBlack += '/logo-black-file';
      }
      if (faviconFile.custom_asset) {
        $scope.methods.favicon = 'put';
        $scope.actionUrl.favicon += '/favicon-file';
      }
      if (profileImageFile.custom_asset) {
        $scope.methods.profileImage = 'put';
        $scope.actionUrl.profileImage += '/profile-image-file';
      }

      privacyDraftsPromise.setting.history.forEach(function (draft) {
        $scope.privacyDraftsHistory.push({ id: draft.id, name: _t('app.admin.settings.privacy.draft_from_USER_DATE', { USER: draft.user.name, DATE: moment(draft.created_at).format('L LT') }), content: draft.value });
      });

      // refresh codemirror to display the fetched setting
      $scope.$watch('advancedSettings.open', function (newValue) {
        if (newValue) $scope.codeMirrorEditor.refresh();
      });

      // use the tours list, based on the selected value
      $scope.$watch('allSettings.feature_tour_display', function (newValue, oldValue, scope) {
        if (newValue === oldValue) return;

        if (newValue === 'session') {
          $scope.currentUser.profile.tours = Fablab.sessionTours;
        } else if (newValue === 'once') {
          Member.get({ id: $scope.currentUser.id }, function (user) {
            $scope.currentUser.profile.tours = user.profile.tours;
          });
        }
      });
    };

    // init the controller (call at the end !)
    return initialize();
  }

]);

/**
 * Controller used in the invoice refunding modal window
 */
Application.Controllers.controller('SavePolicyController', ['$scope', '$uibModalInstance', '_t', 'growl', 'saveCb', 'privacyPolicy',
  function ($scope, $uibModalInstance, _t, growl, saveCb, privacyPolicy) {
    /* PUBLIC SCOPE */

    /**
     * Save as draft the current text
     */
    $scope.save = function () {
      saveCb({ name: 'privacy_draft', value: privacyPolicy.bodyTemp });
      $uibModalInstance.close('privacy_draft');
    };

    /**
     * Publish the current text as the new privacy policy
     */
    $scope.publish = function () {
      saveCb({ name: 'privacy_body', value: privacyPolicy.bodyTemp });
      growl.info(_t('app.admin.settings.privacy.users_notified'));
      $uibModalInstance.close('privacy_body');
    };
    /**
     * Cancel the saving, dismiss the modal window
     */
    $scope.cancel = function () {
      $uibModalInstance.dismiss('cancel');
    };
  }
]);

/**
 * Controller used in the "what do we collect?" modal, about FabAnalytics
 */
Application.Controllers.controller('AnalyticsModalController', ['$scope', '$uibModalInstance', 'analyticsData',
  function ($scope, $uibModalInstance, analyticsData) {
    // analytics data sample
    $scope.data = analyticsData;

    // callback to close the modal
    $scope.close = function () {
      $uibModalInstance.dismiss();
    };
  }
]);

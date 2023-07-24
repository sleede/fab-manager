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

Application.Controllers.controller('AdminProjectsController', ['$scope', '$state', 'Component', 'Licence', 'Theme', 'ProjectCategory', 'componentsPromise', 'licencesPromise', 'themesPromise', 'projectCategoriesPromise', '_t', 'Member', 'uiTourService', 'settingsPromise', 'growl', 'dialogs',
  function ($scope, $state, Component, Licence, Theme, ProjectCategory, componentsPromise, licencesPromise, themesPromise, projectCategoriesPromise, _t, Member, uiTourService, settingsPromise, growl, dialogs) {
    // Materials list (plastic, wood ...)
    $scope.components = componentsPromise;

    // Licences list (Creative Common ...)
    $scope.licences = licencesPromise;

    // Themes list (cooking, sport ...)
    $scope.themes = themesPromise;

    // Project categories list (generic categorization)
    $scope.projectCategories = projectCategoriesPromise;

    // Application settings
    $scope.allSettings = settingsPromise;

    // default tab: materials
    $scope.tabs = { active: 0 };

    /**
     * Saves a new component / Update an existing material to the server (form validation callback)
     * @param data {Object} component name
     * @param [id] {number} component id, in case of update
     */
    $scope.saveComponent = function (data, id) {
      if (id != null) {
        return Component.update({ id }, data);
      } else {
        return Component.save(data, resp => $scope.components[$scope.components.length - 1].id = resp.id);
      }
    };

    /**
     * Deletes the component at the specified index
     * @param index {number} component index in the $scope.components array
     */
    $scope.removeComponent = function (index) {
      Component.delete($scope.components[index]);
      return $scope.components.splice(index, 1);
    };

    /**
     * Creates a new empty entry in the $scope.components array
     */
    $scope.addComponent = function () {
      $scope.inserted = { name: '' };
      $scope.components.push($scope.inserted);
    };

    /**
     * Removes the newly inserted but not saved component / Cancel the current component modification
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} component index in the $scope.components array
     */
    $scope.cancelComponent = function (rowform, index) {
      if ($scope.components[index].id != null) {
        return rowform.$cancel();
      } else {
        return $scope.components.splice(index, 1);
      }
    };

    /**
     * Saves a new theme / Update an existing theme to the server (form validation callback)
     * @param data {Object} theme name
     * @param [data] {number} theme id, in case of update
     */
    $scope.saveTheme = function (data, id) {
      if (id != null) {
        return Theme.update({ id }, data);
      } else {
        return Theme.save(data, resp => $scope.themes[$scope.themes.length - 1].id = resp.id);
      }
    };

    /**
     * Deletes the theme at the specified index
     * @param index {number} theme index in the $scope.themes array
     */
    $scope.removeTheme = function (index) {
      Theme.delete($scope.themes[index]);
      return $scope.themes.splice(index, 1);
    };

    /**
     * Creates a new empty entry in the $scope.themes array
     */
    $scope.addTheme = function () {
      $scope.inserted = { name: '' };
      $scope.themes.push($scope.inserted);
    };

    /**
     * Removes the newly inserted but not saved theme / Cancel the current theme modification
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} theme index in the $scope.themes array
     */
    $scope.cancelTheme = function (rowform, index) {
      if ($scope.themes[index].id != null) {
        rowform.$cancel();
      } else {
        $scope.themes.splice(index, 1);
      }
    };

    /**
     * Saves a new project category / Update an existing project category to the server (form validation callback)
     * @param data {Object} project category name
     * @param [data] {number} project category id, in case of update
     */
    $scope.saveProjectCategory = function (data, id) {
      if (id != null) {
        return ProjectCategory.update({ id }, data);
      } else {
        return ProjectCategory.save(data, resp => $scope.projectCategories[$scope.projectCategories.length - 1].id = resp.id);
      }
    };

    /**
     * Deletes the project category at the specified index
     * @param index {number} project category index in the $scope.projectCategories array
     */
    $scope.removeProjectCategory = function (index) {
      return dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('app.admin.project_categories.delete_dialog_title'),
              msg: _t('app.admin.project_categories.delete_dialog_info')
            };
          }
        }
      }
      , function () { // cancel confirmed
        ProjectCategory.delete($scope.projectCategories[index]);
        $scope.projectCategories.splice(index, 1);
      });
    };

    /**
     * Creates a new empty entry in the $scope.projectCategories array
     */
    $scope.addProjectCategory = function () {
      $scope.inserted = { name: '' };
      $scope.projectCategories.push($scope.inserted);
    };

    /**
     * Removes the newly inserted but not saved project category / Cancel the current project category modification
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} project category index in the $scope.projectCategories array
     */
    $scope.cancelProjectCategory = function (rowform, index) {
      if ($scope.projectCategories[index].id != null) {
        rowform.$cancel();
      } else {
        $scope.projectCategories.splice(index, 1);
      }
    };

    /**
     * Saves a new licence / Update an existing licence to the server (form validation callback)
     * @param data {Object} licence name and description
     * @param [id] {number} licence id, in case of update
     */
    $scope.saveLicence = function (data, id) {
      if (id != null) {
        return Licence.update({ id }, data);
      } else {
        return Licence.save(data, resp => $scope.licences[$scope.licences.length - 1].id = resp.id);
      }
    };

    /**
     * Deletes the licence at the specified index
     * @param index {number} licence index in the $scope.licences array
     */
    $scope.removeLicence = function (index) {
      Licence.delete($scope.licences[index]);
      return $scope.licences.splice(index, 1);
    };

    /**
     * Creates a new empty entry in the $scope.licences array
     */
    $scope.addLicence = function () {
      $scope.inserted = {
        name: '',
        description: ''
      };
      return $scope.licences.push($scope.inserted);
    };

    /**
     * Removes the newly inserted but not saved licence / Cancel the current licence modification
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} licence index in the $scope.licences array
     */
    $scope.cancelLicence = function (rowform, index) {
      if ($scope.licences[index].id != null) {
        return rowform.$cancel();
      } else {
        return $scope.licences.splice(index, 1);
      }
    };

    /**
     * When a file is sent to the server to test it against its MIME type,
     * handle the result of the test.
     */
    $scope.onTestFileComplete = function (res) {
      if (res) {
        growl.success(_t('app.admin.projects.settings.file_is_TYPE', { TYPE: res.type }));
      }
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
     * Remove the initial dot from the given extension, if any
     * @param extension {String}
     * @returns {String}
     */
    $scope.removeInitialDot = function (extension) {
      if (extension.substr(0, 1) === '.') return $scope.lower(extension.substr(1));

      return $scope.lower(extension);
    };

    /**
     * Return the lowercase version of the provided string
     * @param text {String}
     * @returns {string}
     */
    $scope.lower = function (text) {
      return text.toLowerCase();
    };

    /**
     * Setup the feature-tour for the admin/projects page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupProjectElementsTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('projects');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.projects.welcome.title'),
        content: _t('app.admin.tour.projects.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.heading .abuses-button',
        stepId: 'abuses',
        order: 1,
        title: _t('app.admin.tour.projects.abuses.title'),
        content: _t('app.admin.tour.projects.abuses.content'),
        placement: 'bottom',
        popupClass: 'shift-left-40'
      });
      uitour.createStep({
        selector: '.projects .settings-tab',
        stepId: 'settings',
        order: 2,
        title: _t('app.admin.tour.projects.settings.title'),
        content: _t('app.admin.tour.projects.settings.content'),
        placement: 'bottom',
        popupClass: 'shift-left-50'
      });
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 3,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on step change, change the active tab if needed
      uitour.on('stepChanged', function (nextStep) {
        if (nextStep.stepId === 'settings') { $scope.tabs.active = 3; }
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile_attributes.tours.indexOf('projects') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'projects' }, function (res) {
            $scope.currentUser.profile_attributes.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if (settingsPromise.feature_tour_display !== 'manual' && $scope.currentUser.profile_attributes.tours.indexOf('projects') < 0) {
        uitour.start();
      }
    };

    /**
     * Shows a success message forwarded from a child react component
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
    const initialize = function () {};

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

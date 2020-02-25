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

Application.Controllers.controller('ProjectElementsController', ['$scope', '$state', 'Component', 'Licence', 'Theme', 'componentsPromise', 'licencesPromise', 'themesPromise', '_t', 'Member', 'uiTourService',
  function ($scope, $state, Component, Licence, Theme, componentsPromise, licencesPromise, themesPromise, _t, Member, uiTourService) {
    // Materials list (plastic, wood ...)
    $scope.components = componentsPromise;

    // Licences list (Creative Common ...)
    $scope.licences = licencesPromise;

    // Themes list (cooking, sport ...)
    $scope.themes = themesPromise;

    /**
     * Saves a new component / Update an existing material to the server (form validation callback)
     * @param data {Object} component name
     * @param [data] {number} component id, in case of update
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
      $scope.inserted =
      { name: '' };
      return $scope.components.push($scope.inserted);
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
      $scope.inserted =
      { name: '' };
      return $scope.themes.push($scope.inserted);
    };

    /**
     * Removes the newly inserted but not saved theme / Cancel the current theme modification
     * @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
     * @param index {number} theme index in the $scope.themes array
     */
    $scope.cancelTheme = function (rowform, index) {
      if ($scope.themes[index].id != null) {
        return rowform.$cancel();
      } else {
        return $scope.themes.splice(index, 1);
      }
    };

    /**
     * Saves a new licence / Update an existing licence to the server (form validation callback)
     * @param data {Object} licence name and description
     * @param [data] {number} licence id, in case of update
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
     * Setup the feature-tour for the admin/project_elements page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupProjectElementsTour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('project-elements');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.project_elements.welcome.title'),
        content: _t('app.admin.tour.project_elements.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.heading .abuses-button',
        stepId: 'abuses',
        order: 1,
        title: _t('app.admin.tour.project_elements.abuses.title'),
        content: _t('app.admin.tour.project_elements.abuses.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 2,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('project-elements') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'project-elements' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, show him now
      if ($scope.currentUser.profile.tours.indexOf('project-elements') < 0) {
        uitour.start();
      }
      // start this tour when an user press F1 - this is contextual help
      window.addEventListener('keydown', handleF1);
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // listen the $destroy event of the controller to remove the F1 key binding
      $scope.$on('$destroy', function () {
        window.removeEventListener('keydown', handleF1);
      });
    };

    /**
     * Callback used to trigger the feature tour when the user press the F1 key.
     * @param e {KeyboardEvent}
     */
    const handleF1 = function (e) {
      if (e.key === 'F1') {
        e.preventDefault();
        const tour = uiTourService.getTourByName('project-elements');
        if (tour) { tour.start(); }
      }
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

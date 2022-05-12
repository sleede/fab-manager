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
 * DS205: Consider reworking code to avoid use of IIFEs
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/* COMMON CODE */

/**
 * Provides a set of common properties and methods to the $scope parameter. They are used
 * in the various projects' admin controllers.
 *
 * Provides :
 *  - $scope.summernoteOptsProject
 *  - $scope.totalSteps
 *  - $scope.machines = [{Machine}]
 *  - $scope.components = [{Component}]
 *  - $scope.themes = [{Theme}]
 *  - $scope.licences = [{Licence}]
 *  - $scope.allowedExtensions = [{String}]
 *  - $scope.submited(content)
 *  - $scope.cancel()
 *  - $scope.addFile()
 *  - $scope.deleteFile(file)
 *  - $scope.addStep()
 *  - $scope.deleteStep(step)
 *  - $scope.changeStepIndex(step, newIdx)
 *
 * Requires :
 *  - $scope.project.project_caos_attributes = []
 *  - $scope.project.project_steps_attributes = []
 *  - $state (Ui-Router) [ 'app.public.projects_show', 'app.public.projects_list' ]
 */
class ProjectsController {
  constructor ($rootScope, $scope, $state, Project, Machine, Member, Component, Theme, Licence, $document, Diacritics, dialogs, allowedExtensions, _t) {
    // remove codeview from summernote editor
    $scope.summernoteOptsProject = angular.copy($rootScope.summernoteOpts);
    $scope.summernoteOptsProject.toolbar[6][1].splice(1, 1);

    // Retrieve the list of machines from the server
    Machine.query().$promise.then(function (data) {
      $scope.machines = data.map(function (d) {
        return ({
          id: d.id,
          name: d.name
        });
      });
    });

    // Retrieve the list of components from the server
    Component.query().$promise.then(function (data) {
      $scope.components = data.map(function (d) {
        return ({
          id: d.id,
          name: d.name
        });
      });
    });

    // Retrieve the list of themes from the server
    Theme.query().$promise.then(function (data) {
      $scope.themes = data.map(function (d) {
        return ({
          id: d.id,
          name: d.name
        });
      });
    });

    // Retrieve the list of licences from the server
    Licence.query().$promise.then(function (data) {
      $scope.licences = data.map(function (d) {
        return ({
          id: d.id,
          name: d.name
        });
      });
    });

    // Total number of documentation steps for the current project
    $scope.totalSteps = $scope.project.project_steps_attributes.length;

    // List of extensions allowed for CAD attachements upload
    $scope.allowedExtensions = allowedExtensions.setting.value.split(' ');

    /**
     * For use with ngUpload (https://github.com/twilson63/ngUpload).
     * Intended to be the callback when an upload is done: any raised error will be stacked in the
     * $scope.alerts array. If everything goes fine, the user is redirected to the project page.
     * @param content {Object} JSON - The upload's result
     */
    $scope.submited = function (content) {
      if ((content.id == null)) {
        $scope.alerts = [];
        angular.forEach(content, function (v, k) {
          angular.forEach(v, function (err) {
            $scope.alerts.push({
              msg: k + ': ' + err,
              type: 'danger'
            });
          });
        });
        // using https://github.com/oblador/angular-scroll
        $('section[ui-view=main]').scrollTop(0, 200);
      } else {
        return $state.go('app.public.projects_show', { id: content.slug });
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
     * This will create a single new empty entry into the project's CAO attachements list.
     */
    $scope.addFile = function () { $scope.project.project_caos_attributes.push({}); };

    /**
     * This will remove the given file from the project's CAO attachements list. If the file was previously uploaded
     * to the server, it will be marked for deletion on the server. Otherwise, it will be simply truncated from
     * the CAO attachements array.
     * @param file {Object} the file to delete
     */
    $scope.deleteFile = function (file) {
      const index = $scope.project.project_caos_attributes.indexOf(file);
      if (file.id != null) {
        return file._destroy = true;
      } else {
        return $scope.project.project_caos_attributes.splice(index, 1);
      }
    };

    /**
     * This will create a single new empty entry into the project's steps list.
     */
    $scope.addStep = function () {
      $scope.totalSteps += 1;
      return $scope.project.project_steps_attributes.push({ step_nb: $scope.totalSteps, project_step_images_attributes: [] });
    };

    /**
     * This will remove the given step from the project's steps list. If the step was previously saved
     * on the server, it will be marked for deletion for the next saving. Otherwise, it will be simply truncated from
     * the steps array.
     * @param step {Object} the step to delete
     */
    $scope.deleteStep = function (step) {
      dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('app.shared.project.confirmation_required'),
              msg: _t('app.shared.project.do_you_really_want_to_delete_this_step')
            };
          }
        }
      }
      , function () { // deletion confirmed
        const index = $scope.project.project_steps_attributes.indexOf(step);
        if (step.id != null) {
          step._destroy = true;
        } else {
          $scope.project.project_steps_attributes.splice(index, 1);
        }

        // update the new total number of steps
        $scope.totalSteps -= 1;
        // reindex the remaining steps
        return (function () {
          const result = [];
          for (const s of Array.from($scope.project.project_steps_attributes)) {
            if (s.step_nb > step.step_nb) {
              result.push(s.step_nb -= 1);
            } else {
              result.push(undefined);
            }
          }
          return result;
        })();
      });
    };

    /**
     * Change the step_nb property of the given step to the new value provided. The step that was previously at this
     * index will be assigned to the old position of the provided step.
     * @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
     * @param step {Object} the project's step to reindex
     * @param newIdx {number} the new index to assign to the step
     */
    $scope.changeStepIndex = function (event, step, newIdx) {
      if (event) { event.preventDefault(); }
      for (const s of Array.from($scope.project.project_steps_attributes)) {
        if (s.step_nb === newIdx) {
          s.step_nb = step.step_nb;
          step.step_nb = newIdx;
          break;
        }
      }
      return false;
    };

    /**
     * This function will query the API to autocomplete the typed user's name
     * @param nameLookup {string}
     */
    $scope.autoCompleteName = function (nameLookup) {
      if (!nameLookup) {
        return;
      }
      const asciiName = Diacritics.remove(nameLookup);

      Member.search(
        { query: asciiName },
        function (users) { $scope.matchingMembers = users; },
        function (error) { console.error(error); }
      );
    };

    /**
     * This will create a single new empty entry into the project's step image list.
     */
    $scope.addProjectStepImage = function (step) { step.project_step_images_attributes.push({}); };

    /**
     * This will remove the given image from the project's step image list.
     * @param step {Object} the project step has images
     * @param image {Object} the image to delete
     */
    $scope.deleteProjectStepImage = function (step, image) {
      const index = step.project_step_images_attributes.indexOf(image);
      if (image.id != null) {
        return image._destroy = true;
      } else {
        return step.project_step_images_attributes.splice(index, 1);
      }
    };

    /**
     * Returns the text to display on the save button, depending on the current state of the project
     */
    $scope.saveButtonValue = function () {
      if (!$scope.project.state || $scope.project.state === 'draft') {
        return _t('app.shared.project.save_as_draft');
      }
      return _t('app.shared.buttons.save');
    };
  }
}

/**
 *  Controller used on projects listing page
 */
Application.Controllers.controller('ProjectsController', ['$scope', '$state', 'Project', 'machinesPromise', 'themesPromise', 'componentsPromise', 'paginationService', 'OpenlabProject', '$window', 'growl', '_t', '$location', '$timeout', 'settingsPromise', 'openLabActive',
  function ($scope, $state, Project, machinesPromise, themesPromise, componentsPromise, paginationService, OpenlabProject, $window, growl, _t, $location, $timeout, settingsPromise, openLabActive) {
  /* PRIVATE STATIC CONSTANTS */

    // Number of projects added to the page when the user clicks on 'load more projects'
    // -- dependency in app/models/project.rb
    const PROJECTS_PER_PAGE = 16;

    /* PUBLIC SCOPE */

    // Fab-manager's instance ID in the openLab network
    $scope.openlabAppId = settingsPromise.openlab_app_id;

    // Is openLab enabled on the instance?
    $scope.openlab = {
      projectsActive: openLabActive.isPresent,
      searchOverWholeNetwork: settingsPromise.openlab_default === 'true'
    };

    // default search parameters
    $scope.search = {
      q: ($location.$$search.q || ''),
      from: ($location.$$search.from || undefined),
      machine_id: (parseInt($location.$$search.machine_id) || undefined),
      component_id: (parseInt($location.$$search.component_id) || undefined),
      theme_id: (parseInt($location.$$search.theme_id) || undefined)
    };

    // list of projects to display
    $scope.projects = [];

    // list of machines / used for filtering
    $scope.machines = machinesPromise;

    // list of themes / used for filtering
    $scope.themes = themesPromise;

    // list of components / used for filtering
    $scope.components = componentsPromise;

    /**
     * Callback triggered when the button "search from the whole network" is toggled
     */
    $scope.searchOverWholeNetworkChanged = function () {
      $scope.resetFiltersAndTriggerSearch();
    };

    /**
     * Callback to load the next projects of the result set, for the current search
     */
    $scope.loadMore = function () {
      if ($scope.openlab.searchOverWholeNetwork === true) {
        return $scope.projectsPagination.loadMore({ q: $scope.search.q });
      } else {
        return $scope.projectsPagination.loadMore({ search: $scope.search });
      }
    };

    /**
     * Reinitialize the search filters (used by the projects from the instance DB) and trigger a new search query
     */
    $scope.resetFiltersAndTriggerSearch = function () {
      $scope.search.q = '';
      $scope.search.from = undefined;
      $scope.search.machine_id = undefined;
      $scope.search.component_id = undefined;
      $scope.search.theme_id = undefined;
      $scope.setUrlQueryParams($scope.search);
      $scope.triggerSearch();
    };

    /**
     * Query the list of projects. Depending on $scope.openlab.searchOverWholeNetwork, the resulting list
     * will be fetched from OpenLab or from the instance DB
     */
    $scope.triggerSearch = function () {
      const currentPage = parseInt($location.$$search.page) || 1;
      if ($scope.openlab.searchOverWholeNetwork === true) {
        updateUrlParam('whole_network', 't');
        $scope.projectsPagination = new paginationService.Instance(OpenlabProject, currentPage, PROJECTS_PER_PAGE, null, { }, loadMoreOpenlabCallback);
        OpenlabProject.query({ q: $scope.search.q, page: currentPage, per_page: PROJECTS_PER_PAGE }, function (projectsPromise) {
          if (projectsPromise.errors) {
            growl.error(_t('app.public.projects_list.openlab_search_not_available_at_the_moment'));
            $scope.openlab.searchOverWholeNetwork = false;
            $scope.triggerSearch();
          } else {
            $scope.projectsPagination.totalCount = projectsPromise.meta.total;
            $scope.projects = normalizeProjectsAttrs(projectsPromise.projects);
          }
        });
      } else {
        updateUrlParam('whole_network', 'f');
        $scope.projectsPagination = new paginationService.Instance(Project, currentPage, PROJECTS_PER_PAGE, null, { }, loadMoreCallback, 'search');
        Project.search({ search: $scope.search, page: currentPage, per_page: PROJECTS_PER_PAGE }, function (projectsPromise) {
          $scope.projectsPagination.totalCount = projectsPromise.meta.total;
          $scope.projects = projectsPromise.projects;
        });
      }
    };

    /**
     * Callback to switch the user's view to the detailed project page
     * @param project {{slug:string}} The project to display
     */
    $scope.showProject = function (project) {
      if (($scope.openlab.searchOverWholeNetwork === true) && (project.app_id !== Fablab.openlabAppId)) {
        $window.open(project.project_url, '_blank');
        return true;
      } else {
        return $state.go('app.public.projects_show', { id: project.slug });
      }
    };

    /**
     * function to set all url query search parameters from search object
     */
    $scope.setUrlQueryParams = function (search) {
      updateUrlParam('page', 1);
      updateUrlParam('q', search.q);
      updateUrlParam('from', search.from);
      updateUrlParam('theme_id', search.theme_id);
      updateUrlParam('component_id', search.component_id);
      updateUrlParam('machine_id', search.machine_id);
      return true;
    };

    /**
     * Overlap global function to allow the user to navigate to the previous screen
     * If no previous $state were recorded, navigate to the project list page
     */
    $scope.backPrevLocation = function (event) {
      event.preventDefault();
      event.stopPropagation();
      if ($state.prevState === '' || $state.prevState === 'app.public.projects_list') {
        $state.prevState = 'app.public.home';
        return $state.go($state.prevState, {});
      }
      window.history.back();
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      if ($location.$$search.whole_network === 'f') {
        $scope.openlab.searchOverWholeNetwork = false;
      } else if ($location.$$search.whole_network === undefined) {
        $scope.openlab.searchOverWholeNetwork = $scope.openlab.projectsActive && settingsPromise.openlab_default === 'true';
      } else {
        $scope.openlab.searchOverWholeNetwork = $scope.openlab.projectsActive;
      }
      return $scope.triggerSearch();
    };

    /**
     * function to update url query param, little hack to turn off reloadOnSearch and re-enable it after we set the params.
     * params example: 'q' , 'presse-purée'
     */
    const updateUrlParam = function (name, value) {
      $state.current.reloadOnSearch = false;
      $location.search(name, value);
      $timeout(function () { $state.current.reloadOnSearch = undefined; });
    };

    /**
     * Callback triggered when the next projects were loaded from the result set (from the instance DB)
     * @param projectsPromise {{projects: []}}
     */
    const loadMoreCallback = function (projectsPromise) {
      $scope.projects = $scope.projects.concat(projectsPromise.projects);
      updateUrlParam('page', $scope.projectsPagination.currentPage);
    };

    /**
     * Callback triggered when the next projects were loaded from the result set (from OpenLab)
     * @param projectsPromise {{projects: []}}
     */
    const loadMoreOpenlabCallback = function (projectsPromise) {
      $scope.projects = $scope.projects.concat(normalizeProjectsAttrs(projectsPromise.projects));
      updateUrlParam('page', $scope.projectsPagination.currentPage);
    };

    const normalizeProjectsAttrs = function (projects) {
      return projects.map(function (project) {
        project.project_image = project.image_url;
        return project;
      });
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the project creation page
 */
Application.Controllers.controller('NewProjectController', ['$rootScope', '$scope', '$state', 'Project', 'Machine', 'Member', 'Component', 'Theme', 'Licence', '$document', 'CSRF', 'Diacritics', 'dialogs', 'allowedExtensions', '_t',
  function ($rootScope, $scope, $state, Project, Machine, Member, Component, Theme, Licence, $document, CSRF, Diacritics, dialogs, allowedExtensions, _t) {
    CSRF.setMetaTags();

    // API URL where the form will be posted
    $scope.actionUrl = '/api/projects/';

    // Form action on the above URL
    $scope.method = 'post';

    // Default project parameters
    $scope.project = {
      project_steps_attributes: [],
      project_caos_attributes: []
    };

    $scope.matchingMembers = [];

    /*
     * Overlap global function to allow the user to navigate to the previous screen
     * If no previous $state were recorded, navigate to the project list page
     */
    $scope.backPrevLocation = function (event) {
      event.preventDefault();
      event.stopPropagation();
      if ($state.prevState === '') {
        $state.prevState = 'app.public.projects_list';
        return $state.go($state.prevState, {});
      }
      window.history.back();
    };

    // Using the ProjectsController
    return new ProjectsController($rootScope, $scope, $state, Project, Machine, Member, Component, Theme, Licence, $document, Diacritics, dialogs, allowedExtensions, _t);
  }
]);

/**
 * Controller used in the project edition page
 */
Application.Controllers.controller('EditProjectController', ['$rootScope', '$scope', '$state', '$transition$', 'Project', 'Machine', 'Member', 'Component', 'Theme', 'Licence', '$document', 'CSRF', 'projectPromise', 'Diacritics', 'dialogs', 'allowedExtensions', '_t',
  function ($rootScope, $scope, $state, $transition$, Project, Machine, Member, Component, Theme, Licence, $document, CSRF, projectPromise, Diacritics, dialogs, allowedExtensions, _t) {
    /* PUBLIC SCOPE */

    // API URL where the form will be posted
    $scope.actionUrl = `/api/projects/${$transition$.params().id}`;

    // Form action on the above URL
    $scope.method = 'put';

    // Retrieve the project's details, if an error occurred, redirect the user to the projects list page
    $scope.project = projectPromise;

    $scope.matchingMembers = $scope.project.project_users.map(function (u) {
      return ({
        id: u.id,
        name: u.full_name
      });
    });

    /**
     * Overlap global function to allow the user to navigate to the previous screen
     * If no previous $state were recorded, navigate to the project show page
     */
    $scope.backPrevLocation = function (event) {
      event.preventDefault();
      event.stopPropagation();
      if ($state.prevState === '') {
        $state.prevState = 'app.public.projects_show';
      }
      $state.go($state.prevState, { id: $transition$.params().id });
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      CSRF.setMetaTags();

      if ($scope.project.author_id !== $rootScope.currentUser.id && $scope.project.user_ids.indexOf($rootScope.currentUser.id) === -1 && $scope.currentUser.role !== 'admin') {
        $state.go('app.public.projects_show', { id: $scope.project.slug });
        console.error('[EditProjectController::initialize] user is not allowed');
      }

      // Using the ProjectsController
      return new ProjectsController($rootScope, $scope, $state, Project, Machine, Member, Component, Theme, Licence, $document, Diacritics, dialogs, allowedExtensions, _t);
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

/**
 * Controller used in the public project's details page
 */
Application.Controllers.controller('ShowProjectController', ['$scope', '$state', 'projectPromise', 'shortnamePromise', '$location', '$uibModal', 'dialogs', '_t',
  function ($scope, $state, projectPromise, shortnamePromise, $location, $uibModal, dialogs, _t) {
  /* PUBLIC SCOPE */

    // Store the project's details
    $scope.project = projectPromise;
    $scope.projectUrl = $location.absUrl();
    $scope.disqusShortname = shortnamePromise.setting.value;

    /**
     * Test if the provided user has the edition rights on the current project
     * @param [user] {{id:number}} (optional) the user to check rights
     * @returns boolean
     */
    $scope.projectEditableBy = function (user) {
      if ((user == null)) { return false; }
      if ($scope.project.author_id === user.id) { return true; }
      let canEdit = false;
      angular.forEach($scope.project.project_users, function (u) {
        if ((u.id === user.id) && u.is_valid) { return canEdit = true; }
      });
      return canEdit;
    };

    /**
     * Test if the provided user has the deletion rights on the current project
     * @param [user] {{id:number}} (optional) the user to check rights
     * @returns boolean
     */
    $scope.projectDeletableBy = function (user) {
      if ((user == null)) { return false; }
      if ($scope.project.author_id === user.id) { return true; }
    };

    /**
     * Callback to delete the current project. Then, the user is redirected to the projects list page,
     * which is refreshed. Admins and project owner only are allowed to delete a project
     */
    $scope.deleteProject = function () {
    // check the permissions
      if (($scope.currentUser.role === 'admin') || $scope.projectDeletableBy($scope.currentUser)) {
      // delete the project then refresh the projects list
        return dialogs.confirm({
          resolve: {
            object () {
              return {
                title: _t('app.public.projects_show.confirmation_required'),
                msg: _t('app.public.projects_show.do_you_really_want_to_delete_this_project')
              };
            }
          }
        }
        , function () { // cancel confirmed
          $scope.project.$delete(function () { $state.go('app.public.projects_list', {}, { reload: true }); });
        });
      } else {
        return console.error(_t('app.public.projects_show.unauthorized_operation'));
      }
    };

    /**
     * Open a modal box containg a form that allow the end-user to signal an abusive content
     * @param e {Object} jQuery event
     */
    $scope.signalAbuse = function (e) {
      if (e) { e.preventDefault(); }

      $uibModal.open({
        templateUrl: '/shared/signalAbuseModal.html',
        size: 'md',
        resolve: {
          project () { return $scope.project; }
        },
        controller: ['$scope', '$uibModalInstance', '_t', 'growl', 'Abuse', 'project', function ($scope, $uibModalInstance, _t, growl, Abuse, project) {
        // signaler's profile & signalement infos
          $scope.signaler = {
            signaled_type: 'Project',
            signaled_id: project.id
          };

          // callback for signaling cancellation
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };

          // callback for form validation
          return $scope.ok = function () {
            Abuse.save(
              {},
              { abuse: $scope.signaler },
              function (res) {
                // creation successful
                growl.success(_t('app.public.projects_show.your_report_was_successful_thanks'));
                return $uibModalInstance.close(res);
              }
              , function () {
                // creation failed...
                growl.error(_t('app.public.projects_show.an_error_occured_while_sending_your_report'));
              }
            );
          };
        }]
      });
    };

    /**
     * Return the URL allowing to share the current project on the Facebook social network
     */
    $scope.shareOnFacebook = function () { return `https://www.facebook.com/share.php?u=${$state.href('app.public.projects_show', { id: $scope.project.slug }, { absolute: true }).replace('#', '%23')}`; };

    /**
     * Return the URL allowing to share the current project on the Twitter social network
     */
    $scope.shareOnTwitter = function () { return `https://twitter.com/intent/tweet?url=${encodeURIComponent($state.href('app.public.projects_show', { id: $scope.project.slug }, { absolute: true }))}&text=${encodeURIComponent($scope.project.name)}`; };

    /**
     * Overlap global function to allow the user to navigate to the previous screen
     * If no previous $state were recorded, navigate to the project list page
     */
    $scope.backPrevLocation = function (event) {
      event.preventDefault();
      event.stopPropagation();
      if ($state.prevState === '') {
        $state.prevState = 'app.public.projects_list';
        return $state.go($state.prevState, {});
      }
      window.history.back();
    };
  }
]);

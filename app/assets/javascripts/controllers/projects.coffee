'use strict'

### COMMON CODE ###

##
# Provides a set of common properties and methods to the $scope parameter. They are used
# in the various projects' admin controllers.
#
# Provides :
#  - $scope.totalSteps
#  - $scope.machines = [{Machine}]
#  - $scope.components = [{Component}]
#  - $scope.themes = [{Theme}]
#  - $scope.licences = [{Licence}]
#  - $scope.allowedExtensions = [{String}]
#  - $scope.submited(content)
#  - $scope.cancel()
#  - $scope.addFile()
#  - $scope.deleteFile(file)
#  - $scope.addStep()
#  - $scope.deleteStep(step)
#  - $scope.changeStepIndex(step, newIdx)
#
# Requires :
#  - $scope.project.project_caos_attributes = []
#  - $scope.project.project_steps_attributes = []
#  - $state (Ui-Router) [ 'app.public.projects_show', 'app.public.projects_list' ]
##
class ProjectsController
  constructor: ($scope, $state, Project, Machine, Member, Component, Theme, Licence, $document, Diacritics, dialogs, allowedExtensions, _t)->

    ## Retrieve the list of machines from the server
    Machine.query().$promise.then (data)->
      $scope.machines = data.map (d) ->
        id: d.id
        name: d.name

    ## Retrieve the list of components from the server
    Component.query().$promise.then (data)->
      $scope.components = data.map (d) ->
        id: d.id
        name: d.name

    ## Retrieve the list of themes from the server
    Theme.query().$promise.then (data)->
      $scope.themes = data.map (d) ->
        id: d.id
        name: d.name

    ## Retrieve the list of licences from the server
    Licence.query().$promise.then (data)->
      $scope.licences = data.map (d) ->
        id: d.id
        name: d.name

    ## Total number of documentation steps for the current project
    $scope.totalSteps = $scope.project.project_steps_attributes.length

    ## List of extensions allowed for CAD attachements upload
    $scope.allowedExtensions = allowedExtensions



    ##
    # For use with ngUpload (https://github.com/twilson63/ngUpload).
    # Intended to be the callback when an upload is done: any raised error will be stacked in the
    # $scope.alerts array. If everything goes fine, the user is redirected to the project page.
    # @param content {Object} JSON - The upload's result
    ##
    $scope.submited = (content) ->
      if !content.id?
        $scope.alerts = []
        angular.forEach content, (v, k)->
          angular.forEach v, (err)->
            $scope.alerts.push
              msg: k+': '+err
              type: 'danger'
        # using https://github.com/oblador/angular-scroll
        $('section[ui-view=main]').scrollTop(0, 200)
        return
      else
        $state.go('app.public.projects_show', {id: content.slug})



    ##
    # For use with 'ng-class', returns the CSS class name for the uploads previews.
    # The preview may show a placeholder or the content of the file depending on the upload state.
    # @param v {*} any attribute, will be tested for truthiness (see JS evaluation rules)
    ##
    $scope.fileinputClass = (v)->
      if v
        'fileinput-exists'
      else
        'fileinput-new'



    ##
    # This will create a single new empty entry into the project's CAO attachements list.
    ##
    $scope.addFile = ->
      $scope.project.project_caos_attributes.push {}



    ##
    # This will remove the given file from the project's CAO attachements list. If the file was previously uploaded
    # to the server, it will be marked for deletion on the server. Otherwise, it will be simply truncated from
    # the CAO attachements array.
    # @param file {Object} the file to delete
    ##
    $scope.deleteFile = (file) ->
      index = $scope.project.project_caos_attributes.indexOf(file)
      if file.id?
        file._destroy = true
      else
        $scope.project.project_caos_attributes.splice(index, 1)



    ##
    # This will create a single new empty entry into the project's steps list.
    ##
    $scope.addStep = ->
      $scope.totalSteps += 1
      $scope.project.project_steps_attributes.push { step_nb: $scope.totalSteps, project_step_images_attributes: [] }




    ##
    # This will remove the given step from the project's steps list. If the step was previously saved
    # on the server, it will be marked for deletion for the next saving. Otherwise, it will be simply truncated from
    # the steps array.
    # @param file {Object} the file to delete
    ##
    $scope.deleteStep = (step) ->
      dialogs.confirm
        resolve:
          object: ->
            title: _t('confirmation_required')
            msg: _t('do_you_really_want_to_delete_this_step')
        , -> # deletion confirmed
          index = $scope.project.project_steps_attributes.indexOf(step)
          if step.id?
            step._destroy = true
          else
            $scope.project.project_steps_attributes.splice(index, 1)

          # update the new total number of steps
          $scope.totalSteps -= 1
          # reindex the remaning steps
          for s in $scope.project.project_steps_attributes
            if s.step_nb > step.step_nb
              s.step_nb -= 1



    ##
    # Change the step_nb property of the given step to the new value provided. The step that was previously at this
    # index will be assigned to the old position of the provided step.
    # @param event {Object} see https://docs.angularjs.org/guide/expression#-event-
    # @param step {Object} the project's step to reindex
    # @param newIdx {number} the new index to assign to the step
    ##
    $scope.changeStepIndex = (event, step, newIdx) ->
      event.preventDefault() if event
      for s in $scope.project.project_steps_attributes
        if s.step_nb == newIdx
          s.step_nb = step.step_nb
          step.step_nb = newIdx
          break
      false


    $scope.autoCompleteName = (nameLookup) ->
      unless nameLookup
        return
      asciiName = Diacritics.remove(nameLookup)

      Member.search { query: asciiName }, (users) ->
        $scope.matchingMembers = users
      , (error)->
        console.error(error)


    ##
    # This will create a single new empty entry into the project's step image list.
    ##
    $scope.addProjectStepImage = (step)->
      step.project_step_images_attributes.push {}



    ##
    # This will remove the given image from the project's step image list.
    # @param step {Object} the project step has images
    # @param image {Object} the image to delete
    ##
    $scope.deleteProjectStepImage = (step, image) ->
      index = step.project_step_images_attributes.indexOf(image)
      if image.id?
        image._destroy = true
      else
        step.project_step_images_attributes.splice(index, 1)


##
#  Controller used on projects listing page
##
Application.Controllers.controller "ProjectsController", ["$scope", "$state", 'Project', 'machinesPromise', 'themesPromise', 'componentsPromise', 'paginationService', 'OpenlabProject', '$window', 'growl', '_t', '$location', '$timeout'
, ($scope, $state, Project, machinesPromise, themesPromise, componentsPromise, paginationService, OpenlabProject, $window, growl, _t, $location, $timeout) ->

  ### PRIVATE STATIC CONSTANTS ###

  # Number of projects added to the page when the user clicks on 'load more projects'
  PROJECTS_PER_PAGE = 16



  ### PUBLIC SCOPE ###

  ## Fab-manager's instance ID in the openLab network
  $scope.openlabAppId = Fablab.openlabAppId

  ## Is openLab enabled on the instance?
  $scope.openlab =
    projectsActive: Fablab.openlabProjectsActive
    searchOverWholeNetwork: false

  ## default search parameters
  $scope.search =
    q: ($location.$$search.q || "")
    from: ($location.$$search.from || undefined)
    machine_id: (parseInt($location.$$search.machine_id) || undefined)
    component_id: (parseInt($location.$$search.component_id) || undefined)
    theme_id: (parseInt($location.$$search.theme_id) || undefined)

  ## list of projects to display
  $scope.projects = []

  ## list of machines / used for filtering
  $scope.machines = machinesPromise

  ## list of themes / used for filtering
  $scope.themes = themesPromise

  ## list of components / used for filtering
  $scope.components = componentsPromise



  $scope.searchOverWholeNetworkChanged = ->
    setTimeout ->
      $scope.resetFiltersAndTriggerSearch()
    , 150



  $scope.loadMore = ->
    if $scope.openlab.searchOverWholeNetwork is true
      $scope.projectsPagination.loadMore(q: $scope.search.q)
    else
      $scope.projectsPagination.loadMore(search: $scope.search)



  $scope.resetFiltersAndTriggerSearch = ->
    $scope.search.q = ""
    $scope.search.from = undefined
    $scope.search.machine_id = undefined
    $scope.search.component_id = undefined
    $scope.search.theme_id = undefined
    $scope.setUrlQueryParams($scope.search)
    $scope.triggerSearch()



  $scope.triggerSearch = ->
    currentPage = parseInt($location.$$search.page) || 1
    if $scope.openlab.searchOverWholeNetwork is true
      updateUrlParam('whole_network', 't')
      $scope.projectsPagination = new paginationService.Instance(OpenlabProject, currentPage, PROJECTS_PER_PAGE, null, { }, loadMoreOpenlabCallback)
      OpenlabProject.query { q: $scope.search.q, page: currentPage, per_page: PROJECTS_PER_PAGE }, (projectsPromise)->
        if projectsPromise.errors?
          growl.error(_t('openlab_search_not_available_at_the_moment'))
          $scope.openlab.searchOverWholeNetwork = false
          $scope.triggerSearch()
        else
          $scope.projectsPagination.totalCount = projectsPromise.meta.total
          $scope.projects = normalizeProjectsAttrs(projectsPromise.projects)

    else
      updateUrlParam('whole_network', 'f')
      $scope.projectsPagination = new paginationService.Instance(Project, currentPage, PROJECTS_PER_PAGE, null, { }, loadMoreCallback, 'search')
      Project.search { search: $scope.search, page: currentPage, per_page: PROJECTS_PER_PAGE }, (projectsPromise)->
        $scope.projectsPagination.totalCount = projectsPromise.meta.total
        $scope.projects = projectsPromise.projects



  ##
  # Callback to switch the user's view to the detailled project page
  # @param project {{slug:string}} The project to display
  ##
  $scope.showProject = (project) ->
    if ($scope.openlab.searchOverWholeNetwork is true) and (project.app_id isnt Fablab.openlabAppId)
      $window.open(project.project_url, '_blank')
      return true
    else
      $state.go('app.public.projects_show', {id: project.slug})



  ##
  # function to set all url query search parameters from search object
  ##
  $scope.setUrlQueryParams = (search)->
    updateUrlParam('page', 1)
    updateUrlParam('q', search.q)
    updateUrlParam('from', search.from)
    updateUrlParam('theme_id', search.theme_id)
    updateUrlParam('component_id', search.component_id)
    updateUrlParam('machine_id', search.machine_id)



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    if $location.$$search.whole_network is 'f'
      $scope.openlab.searchOverWholeNetwork = false
    else
      $scope.openlab.searchOverWholeNetwork = $scope.openlab.projectsActive || false
    $scope.triggerSearch()


  ##
  # function to update url query param, little hack to turn off reloadOnSearch and re-enable it after setting the params
  # params example: 'q' , 'presse-purée'
  ##
  updateUrlParam = (name, value) ->
    $state.current.reloadOnSearch = false
    $location.search(name, value)
    $timeout ->
      $state.current.reloadOnSearch = undefined



  loadMoreCallback = (projectsPromise)->
    $scope.projects = $scope.projects.concat(projectsPromise.projects)
    updateUrlParam('page', $scope.projectsPagination.currentPage)



  loadMoreOpenlabCallback = (projectsPromise)->
    $scope.projects = $scope.projects.concat(normalizeProjectsAttrs(projectsPromise.projects))
    updateUrlParam('page', $scope.projectsPagination.currentPage)



  normalizeProjectsAttrs = (projects)->
    projects.map((project)->
      project.project_image = project.image_url
      return project
    )



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]



##
# Controller used in the project creation page
##
Application.Controllers.controller "NewProjectController", ["$scope", "$state", 'Project', 'Machine', 'Member', 'Component', 'Theme', 'Licence', '$document', 'CSRF', 'Diacritics', 'dialogs', 'allowedExtensions', '_t'
, ($scope, $state, Project, Machine, Member, Component, Theme, Licence, $document, CSRF, Diacritics, dialogs, allowedExtensions, _t) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/projects/"

  ## Form action on the above URL
  $scope.method = 'post'

  ## Default project parameters
  $scope.project =
    project_steps_attributes: []
    project_caos_attributes: []

  $scope.matchingMembers = []

  ## Using the ProjectsController
  new ProjectsController($scope, $state, Project, Machine, Member, Component, Theme, Licence, $document, Diacritics, dialogs, allowedExtensions, _t)
]



##
# Controller used in the project edition page
##
Application.Controllers.controller "EditProjectController", ["$scope", "$state", '$stateParams', 'Project', 'Machine', 'Member', 'Component', 'Theme', 'Licence', '$document', 'CSRF', 'projectPromise', 'Diacritics', 'dialogs', 'allowedExtensions', '_t'
, ($scope, $state, $stateParams, Project, Machine, Member, Component, Theme, Licence, $document, CSRF, projectPromise, Diacritics, dialogs, allowedExtensions, _t) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/projects/" + $stateParams.id

  ## Form action on the above URL
  $scope.method = 'put'

  ## Retrieve the project's details, if an error occured, redirect the user to the projects list page
  $scope.project = projectPromise

  $scope.matchingMembers = $scope.project.project_users.map (u) ->
    id: u.id
    name: u.full_name

    ## Using the ProjectsController
  new ProjectsController($scope, $state, Project, Machine, Member, Component, Theme, Licence, $document, Diacritics, dialogs, allowedExtensions, _t)
]



##
# Controller used in the public project's details page
##
Application.Controllers.controller "ShowProjectController", ["$scope", "$state", "projectPromise", '$location', '$uibModal', 'dialogs', '_t'
, ($scope, $state, projectPromise, $location, $uibModal, dialogs, _t) ->

  ### PUBLIC SCOPE ###

  ## Store the project's details
  $scope.project = projectPromise
  $scope.projectUrl = $location.absUrl()
  $scope.disqusShortname = Fablab.disqusShortname


  ##
  # Test if the provided user has the edition rights on the current project
  # @param [user] {{id:number}} (optional) the user to check rights
  # @returns boolean
  ##
  $scope.projectEditableBy = (user) ->
    return false if not user?
    return true if $scope.project.author_id == user.id
    canEdit = false
    angular.forEach $scope.project.project_users, (u)->
      canEdit = true if u.id == user.id and u.is_valid
    return canEdit



  ##
  # Test if the provided user has the deletion rights on the current project
  # @param [user] {{id:number}} (optional) the user to check rights
  # @returns boolean
  ##
  $scope.projectDeletableBy = (user) ->
    return false if not user?
    return true if $scope.project.author_id == user.id



  ##
  # Callback to delete the current project. Then, the user is redirected to the projects list page,
  # which is refreshed. Admins and project owner only are allowed to delete a project
  ##
  $scope.deleteProject = ->
    # check the permissions
    if $scope.currentUser.role is 'admin' or $scope.projectDeletableBy($scope.currentUser)
      # delete the project then refresh the projects list
      dialogs.confirm
        resolve:
          object: ->
            title: _t('confirmation_required')
            msg: _t('do_you_really_want_to_delete_this_project')
      , -> # cancel confirmed
        $scope.project.$delete ->
          $state.go('app.public.projects_list', {}, {reload: true})
    else
      console.error _t('unauthorized_operation')



  ##
  # Open a modal box containg a form that allow the end-user to signal an abusive content
  # @param e {Object} jQuery event
  ##
  $scope.signalAbuse = (e) ->
    e.preventDefault() if e

    $uibModal.open
      templateUrl: '<%= asset_path "shared/signalAbuseModal.html" %>'
      size: 'md'
      resolve:
        project: -> $scope.project
      controller: ['$scope', '$uibModalInstance', '_t', 'growl', 'Abuse', 'project', ($scope, $uibModalInstance, _t, growl, Abuse, project) ->

        # signaler's profile & signalement infos
        $scope.signaler = {
          signaled_type: 'Project'
          signaled_id: project.id
        }

        # callback for signaling cancellation
        $scope.cancel = ->
          $uibModalInstance.dismiss('cancel')

        # callback for form validation
        $scope.ok = ->
          Abuse.save {}, {abuse: $scope.signaler}, (res) ->
            # creation successful
            growl.success(_t('your_report_was_successful_thanks'))
            $uibModalInstance.close(res)
          , (error) ->
            # creation failed...
            growl.error(_t('an_error_occured_while_sending_your_report'))
      ]



  ##
  # Return the URL allowing to share the current project on the Facebook social network
  ##
  $scope.shareOnFacebook = ->
    'https://www.facebook.com/share.php?u='+$state.href('app.public.projects_show', {id: $scope.project.slug}, {absolute: true}).replace('#', '%23')



  ##
  # Return the URL allowing to share the current project on the Twitter social network
  ##
  $scope.shareOnTwitter = ->
    'https://twitter.com/intent/tweet?url='+encodeURIComponent($state.href('app.public.projects_show', {id: $scope.project.slug}, {absolute: true}))+'&text='+encodeURIComponent($scope.project.name)
]

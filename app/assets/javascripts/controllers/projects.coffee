'use strict'

### COMMON CODE ###

##
# Provides a set of common properties and methods to the $scope parameter. They are used
# in the various projects' admin controllers.
#
# Provides :
#  - $scope.machines = [{Machine}]
#  - $scope.components = [{Component}]
#  - $scope.themes = [{Theme}]
#  - $scope.licences = [{Licence}]
#  - $scope.submited(content)
#  - $scope.cancel()
#  - $scope.addFile()
#  - $scope.deleteFile(file)
#  - $scope.addStep()
#  - $scope.deleteStep(step)
#
# Requires :
#  - $scope.project.project_caos_attributes = []
#  - $scope.project.project_steps_attributes = []
#  - $state (Ui-Router) [ 'app.public.projects_show', 'app.public.projects_list' ]
##
class ProjectsController
  constructor: ($scope, $state, Project, Machine, Member, Component, Theme, Licence, $document)->

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
        $state.go('app.public.projects_show', {id: content.id})



    ##
    # Changes the user's view to the projects list page
    ##
    $scope.cancel = ->
      $state.go('app.public.projects_list')



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
      $scope.project.project_steps_attributes.push {}



    ##
    # This will remove the given stip from the project's steps list. If the step was previously saved
    # on the server, it will be marked for deletion for the next saving. Otherwise, it will be simply truncated from
    # the steps array.
    # @param file {Object} the file to delete
    ##
    $scope.deleteStep = (step) ->
      index = $scope.project.project_steps_attributes.indexOf(step)
      if step.id?
        step._destroy = true
      else
        $scope.project.project_steps_attributes.splice(index, 1)



##
#  Controller used on projects listing page
##
Application.Controllers.controller "projectsController", ["$scope", "$state", 'Project', 'Machine', 'Theme', 'Component',  ($scope, $state, Project, Machine, Theme, Component) ->



  ### PRIVATE STATIC CONSTANTS ###

  # Number of notifications added to the page when the user clicks on 'load next notifications'
  PROJECTS_PER_PAGE = 12



  ### PUBLIC SCOPE ###

  ## list of projects to display
  $scope.projects = []

  ## list of machines / used for filtering
  $scope.machines = []

  ## list of themes / used for filtering
  $scope.themes = Theme.query()

  ## list of components / used for filtering
  $scope.components = Component.query()

  ## By default, the pagination mode is activated to limit the page size
  $scope.paginateActive = true

  ## The currently displayed page number
  $scope.page = 1



  ##
  # Request the server to retrieve the next undisplayed projects and add them
  # to the local projects list.
  ##
  $scope.loadMoreProjects = ->
    Project.query {page: $scope.page}, (projects) ->
      $scope.projects = $scope.projects.concat projects
      $scope.paginateActive = false if projects.length < PROJECTS_PER_PAGE

    $scope.page += 1



  ##
  # Callback to switch the user's view to the detailled project page
  # @param project {{slug:string}} The project to display
  ##
  $scope.showProject = (project) ->
    $state.go('app.public.projects_show', {id: project.slug})



  ##
  # Callback to delete the provided project. Then, the projects list page is refreshed (admins only)
  ##
  $scope.delete = (project) ->
    # check the permissions
    if $scope.currentUser.role isnt 'admin'
      console.error 'Unauthorized operation'
    else
      # delete the project then refresh the projects list
      project.$delete ->
        $state.go('app.public.projects_list', {}, {reload: true})



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    Machine.query().$promise.then (data)->
      $scope.machines = data.map (d) ->
        id: d.id
        name: d.name

    $scope.loadMoreProjects()



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]



##
# Controller used in the project creation page
##
Application.Controllers.controller "newProjectController", ["$scope", "$state", 'Project', 'Machine', 'Member', 'Component', 'Theme', 'Licence', '$document', 'CSRF', ($scope, $state, Project, Machine, Member, Component, Theme, Licence, $document, CSRF) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/projects/"

  ## Form action on the above URL
  $scope.method = 'post'

  ## Button litteral text value
  $scope.submitName = 'Enregistrer comme brouillon'

  ## Default project parameters
  $scope.project =
    project_steps_attributes: []
    project_caos_attributes: []

  ## Other members list (project collaborators)
  Member.query().$promise.then (data)->
    $scope.members = data.filter (m) ->
      m.id != $scope.currentUser.id
    .map (d) ->
      id: d.id
      name: d.name

  ## Using the ProjectsController
  new ProjectsController($scope, $state, Project, Machine, Member, Component, Theme, Licence, $document)
]



##
# Controller used in the project edition page
##
Application.Controllers.controller "editProjectController", ["$scope", "$state", '$stateParams', 'Project', 'Machine', 'Member', 'Component', 'Theme', 'Licence', '$document', 'CSRF', ($scope, $state, $stateParams, Project, Machine, Member, Component, Theme, Licence, $document, CSRF) ->
  CSRF.setMetaTags()

  ## API URL where the form will be posted
  $scope.actionUrl = "/api/projects/" + $stateParams.id

  ## Form action on the above URL
  $scope.method = 'put'

  ## Button litteral text value
  $scope.submitName = 'Enregistrer'

  ## Retrieve the project's details, if an error occured, redirect the user to the projects list page
  $scope.project = Project.get {id: $stateParams.id}
  , -> # success
    return
  , -> # failed
    $state.go('app.public.projects_list')

  ## Other members list (project collaborators)
  Member.query().$promise.then (data)->
    $scope.members = data.filter (m) ->
      m.id != $scope.project.author_id
    .map (d) ->
      id: d.id
      name: d.name

  ## Using the ProjectsController
  new ProjectsController($scope, $state, Project, Machine, Member, Component, Theme, Licence, $document)
]



##
# Controller used in the public project's details page
##
Application.Controllers.controller "showProjectController", ["$scope", "$state", "$stateParams", "Project", '$location', ($scope, $state, $stateParams, Project, $location) ->



  ### PUBLIC SCOPE ###

  ## Will be set to true once the project details are loaded. Used to load the Disqus plugin at the right moment
  $scope.contentLoaded = false

  ## Store the project's details
  $scope.project = {}



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



  ### PRIVATE SCOPE ###

  ##
  # Kind of constructor: these actions will be realized first when the controller is loaded
  ##
  initialize = ->
    ## Retrieve the project content
    $scope.project = Project.get {id: $stateParams.id}
    , -> # success
      $scope.contentLoaded = true
      $scope.project_url = $location.absUrl()
      return
    , -> # failed, redirect the user to the projects listing
      $state.go('app.public.projects_list')



  ## !!! MUST BE CALLED AT THE END of the controller
  initialize()
]

'use strict'

# filter for projects and trainings
Application.Controllers.filter "machineFilter", [ ->
  (elements, selectedMachine) ->
    if !angular.isUndefined(elements) and !angular.isUndefined(selectedMachine) and elements? and selectedMachine?
      filteredElements = []
      angular.forEach elements, (element)->
        if element.machine_ids.indexOf(selectedMachine) != -1
          filteredElements.push(element)
      filteredElements
    else
      elements
]

Application.Controllers.filter "projectMemberFilter", [ "Auth", (Auth)->
  (projects, selectedMember) ->
    if !angular.isUndefined(projects) and angular.isDefined(selectedMember) and projects? and selectedMember? and selectedMember != ""
      filteredProject = []
      # Mes projets
      if selectedMember == '0'
        angular.forEach projects, (project)->
          if project.author_id == Auth._currentUser.id
            filteredProject.push(project)
      # les projets auxquels je collabore
      else
        angular.forEach projects, (project)->
          if project.user_ids.indexOf(Auth._currentUser.id) != -1
            filteredProject.push(project)
      filteredProject
    else
      projects
]

Application.Controllers.filter "themeFilter", [ ->
  (projects, selectedTheme) ->
    if !angular.isUndefined(projects) and !angular.isUndefined(selectedTheme) and projects? and selectedTheme?
      filteredProjects = []
      angular.forEach projects, (project)->
        if project.theme_ids.indexOf(selectedTheme) != -1
          filteredProjects.push(project)
      filteredProjects
    else
      projects
]

Application.Controllers.filter "componentFilter", [ ->
  (projects, selectedComponent) ->
    if !angular.isUndefined(projects) and !angular.isUndefined(selectedComponent) and projects? and selectedComponent?
      filteredProjects = []
      angular.forEach projects, (project)->
        if project.component_ids.indexOf(selectedComponent) != -1
          filteredProjects.push(project)
      filteredProjects
    else
      projects
]

Application.Controllers.filter "projectsByAuthor", [ ->
  (projects, authorId) ->
    if !angular.isUndefined(projects) and angular.isDefined(authorId) and projects? and authorId? and authorId != ""
      filteredProject = []
      angular.forEach projects, (project)->
        if project.author_id == authorId
          filteredProject.push(project)
      filteredProject
    else
      projects
]

Application.Controllers.filter "projectsCollabored", [ ->
  (projects, memberId) ->
    if !angular.isUndefined(projects) and angular.isDefined(memberId) and projects? and memberId? and memberId != ""
      filteredProject = []
      angular.forEach projects, (project)->
        if project.user_ids.indexOf(memberId) != -1
          filteredProject.push(project)
      filteredProject
    else
      projects
]

# depend on humanize.js lib in /vendor
Application.Controllers.filter "humanize", [ ->
  (element, param) ->
    Humanize.truncate(element, param, null)
]

Application.Controllers.filter "breakFilter", [ ->
  (text) ->
    if text != undefined
      text.replace(/\n/g, '<br />')
]

Application.Controllers.filter "toTrusted", [ "$sce", ($sce) ->
  (text) ->
    $sce.trustAsHtml text
]


Application.Controllers.filter "eventsFilter", [ ->
  (elements, selectedScope) ->
    if !angular.isUndefined(elements) and !angular.isUndefined(selectedScope) and elements? and selectedScope? and selectedScope != ""
      filteredElements = []
      angular.forEach elements, (element)->
        element.start_at = element.availability.start_at if angular.isUndefined(element.start_at)
        switch selectedScope
          when "future"
            if new Date(element.start_at) > new Date
              filteredElements.push(element)
          when "passed"
            if new Date(element.start_at) <= new Date
              filteredElements.push(element)
          else
            return []
      filteredElements
    else
      elements
]

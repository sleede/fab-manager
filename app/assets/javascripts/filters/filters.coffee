'use strict'

Application.Filters.filter 'array', [ ->
  (arrayLength) ->
    if (arrayLength)
      arrayLength = Math.ceil(arrayLength)
      arr = new Array(arrayLength)

      for i in [0 ... arrayLength]
        arr[i] = i

      arr
]

# filter for projects and trainings
Application.Filters.filter "machineFilter", [ ->
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

Application.Filters.filter "projectMemberFilter", [ "Auth", (Auth)->
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

Application.Filters.filter "themeFilter", [ ->
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

Application.Filters.filter "componentFilter", [ ->
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

Application.Filters.filter "projectsByAuthor", [ ->
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

Application.Filters.filter "projectsCollabored", [ ->
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
Application.Filters.filter "humanize", [ ->
  (element, param) ->
    Humanize.truncate(element, param, null)
]

##
# This filter will convert ASCII carriage-return character to the HTML break-line tag
##
Application.Filters.filter "breakFilter", [ ->
  (text) ->
    if text?
      text.replace(/\n+/g, '<br />')
]

##
# This filter will take a HTML text as input and will return it without the html tags
##
Application.Filters.filter "simpleText", [ ->
  (text) ->
    if text?
      text = text.replace(/<br\s*\/?>/g, '\n')
      text.replace(/<\/?\w+[^>]*>/g, '')
    else
      ""
]

Application.Filters.filter "toTrusted", [ "$sce", ($sce) ->
  (text) ->
    $sce.trustAsHtml text
]


Application.Filters.filter "planIntervalFilter", [ ->
  (interval, intervalCount) ->
    moment.duration(intervalCount, interval).humanize()
]

Application.Filters.filter "humanReadablePlanName", ['$filter', ($filter)->
  (plan, groups, short) ->
    if plan?
      result = plan.base_name
      if groups?
        for group in groups
          if group.id == plan.group_id
            if short?
              result += " - #{group.slug}"
            else
              result += " - #{group.name}"
      result += " - #{$filter('planIntervalFilter')(plan.interval, plan.interval_count)}"
      result
]

Application.Filters.filter "trainingReservationsFilter", [ ->
  (elements, selectedScope) ->
    if !angular.isUndefined(elements) and !angular.isUndefined(selectedScope) and elements? and selectedScope?
      filteredElements = []
      angular.forEach elements, (element)->
        switch selectedScope
          when "future"
            if new Date(element.start_at) > new Date
              filteredElements.push(element)
          when "passed"
            if new Date(element.start_at) <= new Date and !element.is_valid
              filteredElements.push(element)
          when "valided"
            if new Date(element.start_at) <= new Date and element.is_valid
              filteredElements.push(element)
          else
            return []
      filteredElements
    else
      elements
]

Application.Filters.filter "eventsReservationsFilter", [ ->
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

Application.Filters.filter "groupFilter", [ ->
  (elements, member) ->
    if !angular.isUndefined(elements) and !angular.isUndefined(member) and elements? and member?
      filteredElements = []
      angular.forEach elements, (element)->
        if member.group_id == element.id
          filteredElements.push(element)
      filteredElements
    else
      elements
]

Application.Filters.filter "groupByFilter", [ ->
  _.memoize (elements, field)->
    _.groupBy(elements, field)
]

Application.Filters.filter "capitalize", [->
  (text)->
    "#{text.charAt(0).toUpperCase()}#{text.slice(1).toLowerCase()}"
]


Application.Filters.filter 'reverse', [ ->
  (items) ->
    unless angular.isArray(items)
      return items

    items.slice().reverse()
]

Application.Filters.filter 'toArray', [ ->
  (obj) ->
    return obj unless (obj instanceof Object)
    _.map obj, (val, key) ->
      if angular.isObject(val)
        Object.defineProperty(val, '$key', {__proto__: null, value: key})

]

Application.Filters.filter 'toIsoDate', [ ->
  (date) ->
    return date unless (date instanceof Date || moment.isMoment(date))
    moment(date).format('YYYY-MM-DD')

]

Application.Filters.filter 'booleanFormat', [ '_t', (_t) ->
  (boolean) ->
    if boolean or boolean == 'true'
      _t('yes')
    else
      _t('no')
]

Application.Filters.filter 'booleanFormat', [ '_t', (_t) ->
  (boolean) ->
    if (typeof boolean == 'boolean' and boolean) or (typeof boolean == 'string' and boolean == 'true')
      _t('yes')
    else
      _t('no')
]

Application.Filters.filter 'maxCount', [ '_t', (_t) ->
  (max) ->
    if typeof max == 'undefined' or max == null or (typeof max == 'number' and max == 0)
      _t('unlimited')
    else
      max
]


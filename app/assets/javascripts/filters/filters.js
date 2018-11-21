/* eslint-disable
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict'

Application.Filters.filter('array', [ () =>
  function (arrayLength) {
    if (arrayLength) {
      arrayLength = Math.ceil(arrayLength)
      const arr = new Array(arrayLength)

      for (let i = 0, end = arrayLength, asc = end >= 0; asc ? i < end : i > end; asc ? i++ : i--) {
        arr[i] = i
      }

      return arr
    }
  }

])

// filter for projects and trainings
Application.Filters.filter('machineFilter', [ () =>
  function (elements, selectedMachine) {
    if (!angular.isUndefined(elements) && !angular.isUndefined(selectedMachine) && (elements != null) && (selectedMachine != null)) {
      const filteredElements = []
      angular.forEach(elements, function (element) {
        if (element.machine_ids.indexOf(selectedMachine) !== -1) {
          return filteredElements.push(element)
        }
      })
      return filteredElements
    } else {
      return elements
    }
  }

])

Application.Filters.filter('projectMemberFilter', [ 'Auth', Auth =>
  function (projects, selectedMember) {
    if (!angular.isUndefined(projects) && angular.isDefined(selectedMember) && (projects != null) && (selectedMember != null) && (selectedMember !== '')) {
      const filteredProject = []
      // Mes projets
      if (selectedMember === '0') {
        angular.forEach(projects, function (project) {
          if (project.author_id === Auth._currentUser.id) {
            return filteredProject.push(project)
          }
        })
      // les projets auxquels je collabore
      } else {
        angular.forEach(projects, function (project) {
          if (project.user_ids.indexOf(Auth._currentUser.id) !== -1) {
            return filteredProject.push(project)
          }
        })
      }
      return filteredProject
    } else {
      return projects
    }
  }

])

Application.Filters.filter('themeFilter', [ () =>
  function (projects, selectedTheme) {
    if (!angular.isUndefined(projects) && !angular.isUndefined(selectedTheme) && (projects != null) && (selectedTheme != null)) {
      const filteredProjects = []
      angular.forEach(projects, function (project) {
        if (project.theme_ids.indexOf(selectedTheme) !== -1) {
          return filteredProjects.push(project)
        }
      })
      return filteredProjects
    } else {
      return projects
    }
  }

])

Application.Filters.filter('componentFilter', [ () =>
  function (projects, selectedComponent) {
    if (!angular.isUndefined(projects) && !angular.isUndefined(selectedComponent) && (projects != null) && (selectedComponent != null)) {
      const filteredProjects = []
      angular.forEach(projects, function (project) {
        if (project.component_ids.indexOf(selectedComponent) !== -1) {
          return filteredProjects.push(project)
        }
      })
      return filteredProjects
    } else {
      return projects
    }
  }

])

Application.Filters.filter('projectsByAuthor', [ () =>
  function (projects, authorId) {
    if (!angular.isUndefined(projects) && angular.isDefined(authorId) && (projects != null) && (authorId != null) && (authorId !== '')) {
      const filteredProject = []
      angular.forEach(projects, function (project) {
        if (project.author_id === authorId) {
          return filteredProject.push(project)
        }
      })
      return filteredProject
    } else {
      return projects
    }
  }

])

Application.Filters.filter('projectsCollabored', [ () =>
  function (projects, memberId) {
    if (!angular.isUndefined(projects) && angular.isDefined(memberId) && (projects != null) && (memberId != null) && (memberId !== '')) {
      const filteredProject = []
      angular.forEach(projects, function (project) {
        if (project.user_ids.indexOf(memberId) !== -1) {
          return filteredProject.push(project)
        }
      })
      return filteredProject
    } else {
      return projects
    }
  }

])

// depend on humanize.js lib in /vendor
Application.Filters.filter('humanize', [ () =>
  (element, param) => Humanize.truncate(element, param, null)

])

/**
 * This filter will convert ASCII carriage-return character to the HTML break-line tag
 */
Application.Filters.filter('breakFilter', [ () =>
  function (text) {
    if (text != null) {
      return text.replace(/\n+/g, '<br />')
    }
  }

])

/**
 * This filter will take a HTML text as input and will return it without the html tags
 */
Application.Filters.filter('simpleText', [ () =>
  function (text) {
    if (text != null) {
      text = text.replace(/<br\s*\/?>/g, '\n')
      return text.replace(/<\/?\w+[^>]*>/g, '')
    } else {
      return ''
    }
  }

])

Application.Filters.filter('toTrusted', [ '$sce', $sce =>
  text => $sce.trustAsHtml(text)

])

Application.Filters.filter('planIntervalFilter', [ () =>
  (interval, intervalCount) => moment.duration(intervalCount, interval).humanize()

])

Application.Filters.filter('humanReadablePlanName', ['$filter', $filter =>
  function (plan, groups, short) {
    if (plan != null) {
      let result = plan.base_name
      if (groups != null) {
        for (let group of Array.from(groups)) {
          if (group.id === plan.group_id) {
            if (short != null) {
              result += ` - ${group.slug}`
            } else {
              result += ` - ${group.name}`
            }
          }
        }
      }
      result += ` - ${$filter('planIntervalFilter')(plan.interval, plan.interval_count)}`
      return result
    }
  }

])

Application.Filters.filter('trainingReservationsFilter', [ () =>
  function (elements, selectedScope) {
    if (!angular.isUndefined(elements) && !angular.isUndefined(selectedScope) && (elements != null) && (selectedScope != null)) {
      const filteredElements = []
      angular.forEach(elements, function (element) {
        switch (selectedScope) {
          case 'future':
            if (new Date(element.start_at) > new Date()) {
              return filteredElements.push(element)
            }
            break
          case 'passed':
            if ((new Date(element.start_at) <= new Date()) && !element.is_valid) {
              return filteredElements.push(element)
            }
            break
          case 'valided':
            if ((new Date(element.start_at) <= new Date()) && element.is_valid) {
              return filteredElements.push(element)
            }
            break
          default:
            return []
        }
      })
      return filteredElements
    } else {
      return elements
    }
  }

])

Application.Filters.filter('eventsReservationsFilter', [ () =>
  function (elements, selectedScope) {
    if (!angular.isUndefined(elements) && !angular.isUndefined(selectedScope) && (elements != null) && (selectedScope != null) && (selectedScope !== '')) {
      const filteredElements = []
      angular.forEach(elements, function (element) {
        if (angular.isUndefined(element.start_at)) { element.start_at = element.availability.start_at }
        if (angular.isUndefined(element.end_at)) { element.end_at = element.availability.end_at }
        switch (selectedScope) {
          case 'future':
            if (new Date(element.end_at) >= new Date()) {
              return filteredElements.push(element)
            }
            break
          case 'future_asc':
            if (new Date(element.end_at) >= new Date()) {
              return filteredElements.push(element)
            }
            break
          case 'passed':
            if (new Date(element.end_at) <= new Date()) {
              return filteredElements.push(element)
            }
            break
          default:
            return []
        }
      })
      switch (selectedScope) {
        case 'future_asc':
          return filteredElements.reverse()
        default:
          return filteredElements
      }
    } else {
      return elements
    }
  }

])

Application.Filters.filter('groupFilter', [ () =>
  function (elements, member) {
    if (!angular.isUndefined(elements) && !angular.isUndefined(member) && (elements != null) && (member != null)) {
      const filteredElements = []
      angular.forEach(elements, function (element) {
        if (member.group_id === element.id) {
          return filteredElements.push(element)
        }
      })
      return filteredElements
    } else {
      return elements
    }
  }

])

Application.Filters.filter('groupByFilter', [ () =>
  _.memoize((elements, field) => _.groupBy(elements, field))

])

Application.Filters.filter('capitalize', [() =>
  text => `${text.charAt(0).toUpperCase()}${text.slice(1).toLowerCase()}`

])

Application.Filters.filter('reverse', [ () =>
  function (items) {
    if (!angular.isArray(items)) {
      return items
    }

    return items.slice().reverse()
  }

])

Application.Filters.filter('toArray', [ () =>
  function (obj) {
    if (!(obj instanceof Object)) { return obj }
    return _.map(obj, function (val, key) {
      if (angular.isObject(val)) {
        return Object.defineProperty(val, '$key', { __proto__: null, value: key })
      }
    })
  }

])

Application.Filters.filter('toIsoDate', [ () =>
  function (date) {
    if (!(date instanceof Date) && !moment.isMoment(date)) { return date }
    return moment(date).format('YYYY-MM-DD')
  }

])

Application.Filters.filter('booleanFormat', [ '_t', _t =>
  function (boolean) {
    if (boolean || (boolean === 'true')) {
      return _t('yes')
    } else {
      return _t('no')
    }
  }

])

Application.Filters.filter('booleanFormat', [ '_t', _t =>
  function (boolean) {
    if (((typeof boolean === 'boolean') && boolean) || ((typeof boolean === 'string') && (boolean === 'true'))) {
      return _t('yes')
    } else {
      return _t('no')
    }
  }

])

Application.Filters.filter('maxCount', [ '_t', _t =>
  function (max) {
    if ((typeof max === 'undefined') || (max === null) || ((typeof max === 'number') && (max === 0))) {
      return _t('unlimited')
    } else {
      return max
    }
  }

])

Application.Filters.filter('filterDisabled', [ () =>
  function (list, filter) {
    if (angular.isArray(list)) {
      return list.filter(function (e) {
        switch (filter) {
          case 'disabled': return e.disabled
          case 'enabled': return !e.disabled
          default: return true
        }
      })
    } else {
      return list
    }
  }

])

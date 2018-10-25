'use strict'

Application.Directives.directive 'url', [ ->
  URL_REGEXP = /^(https?:\/\/)([\da-z\.-]+)\.([-a-z0-9\.]{2,30})([\/\w \.-]*)*\/?$/
  {
    require: 'ngModel'
    link: (scope, element, attributes, ctrl) ->
      ctrl.$validators.url = (modelValue, viewValue) ->
        if ctrl.$isEmpty(modelValue)
          return true
        if URL_REGEXP.test(viewValue)
          return true

        # otherwise, this is invalid
        return false
  }
]


Application.Directives.directive 'endpoint', [ ->
  ENDPOINT_REGEXP = /^\/?([-._~:?#\[\]@!$&'()*+,;=%\w]+\/?)*$/
  {
    require: 'ngModel'
    link: (scope, element, attributes, ctrl) ->
      ctrl.$validators.endpoint = (modelValue, viewValue) ->
        if ctrl.$isEmpty(modelValue)
          return true
        if ENDPOINT_REGEXP.test(viewValue)
          return true

        # otherwise, this is invalid
        return false
  }
]
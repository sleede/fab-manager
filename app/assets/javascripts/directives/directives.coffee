'use strict'

Application.Directives.directive 'fileread', [ ->
  {
  scope:
    fileread: "="

  link: (scope, element, attributes) ->
    element.bind "change", (changeEvent) ->
      scope.$apply ->
        scope.fileread = changeEvent.target.files[0]
  }
]

# This `bsHolder` angular directive is a workaround for
# an incompatability between angular and the holder.js
# image placeholder library.
#
# To use, simply define `bs-holder` on any element
Application.Directives.directive 'bsHolder', [ ->
  {
  link: (scope, element, attrs) ->
    Holder.addTheme("icon", { background: "white", foreground: "#e9e9e9", size: 80, font: "FontAwesome"})
    .addTheme("icon-xs", { background: "white", foreground: "#e0e0e0", size: 20, font: "FontAwesome"})
    .addTheme("icon-black-xs", { background: "black", foreground: "white", size: 20, font: "FontAwesome"})
    .addTheme("avatar", { background: "#eeeeee", foreground: "#555555", size: 16, font: "FontAwesome"})
    .run(element[0])
    return
  }
]

Application.Directives.directive 'match', [ ->
  {
  require: 'ngModel'
  restrict: 'A'
  scope:
    match: '='
  link: (scope, elem, attrs, ctrl) ->
    scope.$watch ->
      (ctrl.$pristine && angular.isUndefined(ctrl.$modelValue)) || scope.match == ctrl.$modelValue
    , (currentValue) ->
      ctrl.$setValidity('match', currentValue)
  }
]

Application.Directives.directive 'publishProject', [ ->
  {
  restrict: 'A'
  link: (scope, elem, attrs, ctrl) ->
    elem.bind 'click', ($event)->
      if ($event)
        $event.preventDefault()
        $event.stopPropagation()

      return if (elem.attr('disabled'))
      input = angular.element('<input name="project[state]" type="hidden" value="published">')
      form = angular.element('form')
      form.append(input)
      form.triggerHandler('submit')
      form[0].submit()
  }
]


Application.Directives.directive "disableAnimation", ($animate) ->
  restrict: "A"
  link: (scope, elem, attrs) ->
    attrs.$observe "disableAnimation", (value) ->
      $animate.enabled not value, elem


##
# Isolate a form's scope from its parent : no nested validation
##
Application.Directives.directive 'isolateForm', [ ->
  {
    restrict: 'A',
    require: '?form'
    link: (scope, elm, attrs, ctrl) ->
      return unless ctrl

      # Do a copy of the controller
      ctrlCopy = {}
      angular.copy(ctrl, ctrlCopy)

      # Get the form's parent
      parent = elm.parent().controller('form')
      # Remove parent link to the controller
      parent.$removeControl(ctrl)

      # Replace form controller with a "isolated form"
      isolatedFormCtrl =
        $setValidity: (validationToken, isValid, control) ->
          ctrlCopy.$setValidity(validationToken, isValid, control);
          parent.$setValidity(validationToken, true, ctrl);

        $setDirty: ->
          elm.removeClass('ng-pristine').addClass('ng-dirty');
          ctrl.$dirty = true;
          ctrl.$pristine = false;

      angular.extend(ctrl, isolatedFormCtrl)

  }
]
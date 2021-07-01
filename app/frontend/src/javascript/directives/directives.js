/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Directives.directive('fileread', [() =>
  ({
    scope: {
      fileread: '='
    },

    link (scope, element, attributes) {
      return element.bind('change', changeEvent =>
        scope.$apply(() => scope.fileread = changeEvent.target.files[0])
      );
    }
  })

]);

// This `bsHolder` angular directive is a workaround for
// an incompatability between angular and the holder.js
// image placeholder library.
//
// To use, simply define `bs-holder` on any element
Application.Directives.directive('bsHolder', [() =>
  ({
    link (scope, element, attrs) {
      Holder.addTheme('icon', { background: 'white', foreground: '#e9e9e9', size: 80, font: 'FontAwesome' })
        .addTheme('icon-xs', { background: 'white', foreground: '#e0e0e0', size: 20, font: 'FontAwesome' })
        .addTheme('icon-black-xs', { background: 'black', foreground: 'white', size: 20, font: 'FontAwesome' })
        .addTheme('avatar', { background: '#eeeeee', foreground: '#555555', size: 16, font: 'FontAwesome' })
        .run(element[0]);
    }
  })

]);

Application.Directives.directive('match', [() =>
  ({
    require: 'ngModel',
    restrict: 'A',
    scope: {
      match: '='
    },
    link (scope, elem, attrs, ctrl) {
      return scope.$watch(() => (ctrl.$pristine && angular.isUndefined(ctrl.$modelValue)) || (scope.match === ctrl.$modelValue)
        , currentValue => ctrl.$setValidity('match', currentValue));
    }
  })

]);

Application.Directives.directive('publishProject', [() =>
  ({
    restrict: 'A',
    link (scope, elem, attrs, ctrl) {
      return elem.bind('click', function ($event) {
        if ($event) {
          $event.preventDefault();
          $event.stopPropagation();
        }

        if (elem.attr('disabled')) { return; }
        const input = angular.element('<input name="project[state]" type="hidden" value="published">');
        const form = angular.element('form');
        form.append(input);
        form.triggerHandler('submit');
        return form[0].submit();
      });
    }
  })

]);

Application.Directives.directive('disableAnimation', ['$animate', ($animate) =>
  ({
    restrict: 'A',
    link (scope, elem, attrs) {
      return attrs.$observe('disableAnimation', value => $animate.enabled(elem, !value));
    }
  })
]);

/**
 * Isolate a form's scope from its parent : no nested validation
 * @see https://stackoverflow.com/a/37481846/1039377
 */
Application.Directives.directive('isolateForm', [() =>
  ({
    restrict: 'A',
    require: '?form',
    link (scope, elm, attrs, ctrl) {
      if (!ctrl) { return; }

      const parentForm = ctrl.$$parentForm; // Note this uses private API
      if (!parentForm) {
        return;
      }

      // Remove this form from parent controller
      parentForm.$removeControl(ctrl);
    }

  })

]);

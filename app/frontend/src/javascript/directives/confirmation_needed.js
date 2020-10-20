/* eslint-disable
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
Application.Directives.directive('confirmationNeeded', [() =>
  ({
    priority: 1,
    terminal: true,
    link (scope, element, attrs) {
      const msg = attrs.confirmationNeeded || 'Are you sure?';
      const clickAction = attrs.ngClick;
      return element.bind('click', function () {
        if (attrs.confirmationNeededIf != null) {
          const confirmNeededIf = scope.$eval(attrs.confirmationNeededIf);
          if (confirmNeededIf === true) {
            if (window.confirm(msg)) {
              return scope.$eval(clickAction);
            }
          } else {
            return scope.$eval(clickAction);
          }
        } else {
          if (window.confirm(msg)) {
            return scope.$eval(clickAction);
          }
        }
      });
    }
  })

]);

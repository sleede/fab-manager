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
Application.Directives.directive('socialLink', [ function () {
  return ({
    restrict: 'E',
    scope: {
      network: '@?',
      user: '='
    },
    templateUrl: '../../../templates/shared/_social_link.html',
    link (scope, element, attributes) {
      if (scope.network === 'dailymotion') {
        scope.image = "social/dailymotion.png";
        return scope.altText = 'd';
      } else if (scope.network === 'echosciences') {
        scope.image = "social/echosciences.png";
        return scope.altText = 'E)';
      } else {
        if (scope.network === 'website') {
          return scope.faClass = 'fa-globe';
        } else {
          return scope.faClass = `fa-${scope.network.replace('_', '-')}`;
        }
      }
    }
  });
}]);

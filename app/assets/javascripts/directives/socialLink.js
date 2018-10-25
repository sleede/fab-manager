/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
Application.Directives.directive('socialLink', [ () =>
  ({
    restrict: 'E',
    scope: {
      network: '@?',
      user: '='
    },
    templateUrl: '<%= asset_path "shared/_social_link.html" %>',
    link(scope, element, attributes) {
      if (scope.network === 'dailymotion') {
        scope.image = "<%= asset_path('social/dailymotion.png') %>";
        return scope.altText = 'd';
      } else if (scope.network === 'echosciences') {
        scope.image = "<%= asset_path('social/echosciences.png') %>";
        return scope.altText = 'E)';
      } else {
        if (scope.network === 'website') {
          return scope.faClass = 'fa-globe';
        } else {
          return scope.faClass = `fa-${scope.network.replace('_', '-')}`;
        }
      }
    }
  })

]);



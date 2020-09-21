'use strict';

/**
 * This directive will allow to select a member.
 * Please surround it with a ng-if directive to prevent it from being used by a non-admin user.
 * The resulting member will be set into the parent $scope (=> $scope.ctrl.member).
 * The directive takes an optional parameter "subscription" as a "boolean string" that will filter the user
 * which have a valid running subscription or not.
 * Usage: <select-member [subscription="false|true"]></select-member>
 */
Application.Directives.directive('selectMember', [ 'Diacritics', 'Member', function (Diacritics, Member) {
  return ({
    restrict: 'E',
    template: require('../../../templates/shared/_member_select.html'),
    link (scope, element, attributes) {
      return scope.autoCompleteName = function (nameLookup) {
        if (!nameLookup) {
          return;
        }
        scope.isLoadingMembers = true;
        const asciiName = Diacritics.remove(nameLookup);

        const q = { query: asciiName };
        if (attributes.subscription) {
          q['subscription'] = attributes.subscription;
        }

        Member.search(q, function (users) {
          scope.matchingMembers = users;
          scope.isLoadingMembers = false;
        }
        , function (error) { console.error(error); });
      };
    }

  });
}]);

'use strict'

##
# This directive will allow to select a member.
# Please surround it with a ng-if directive to prevent it from being used by a non-admin user.
# The resulting member will be set into the parent $scope (=> $scope.ctrl.member).
# The directive takes an optional parameter "subscription" as a "boolean string" that will filter the user
# which have a valid running subscription or not.
# Usage: <select-member [subscription="false|true"]></select-member>
##
Application.Directives.directive 'selectMember', [ 'Diacritics', 'Member', (Diacritics, Member) ->
  {
    restrict: 'E'
    templateUrl: '<%= asset_path "shared/_member_select.html" %>'
    link: (scope, element, attributes) ->
      scope.autoCompleteName = (nameLookup) ->
        unless nameLookup
          return
        scope.isLoadingMembers = true
        asciiName = Diacritics.remove(nameLookup)

        q = { query: asciiName }
        if attributes.subscription
          q['subscription'] = attributes.subscription

        Member.search q, (users) ->
          scope.matchingMembers = users
          scope.isLoadingMembers = false
        , (error)->
          console.error(error)

  }
]


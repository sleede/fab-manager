/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Services.factory('Translations', ["$translatePartialLoader", "$translate", ($translatePartialLoader, $translate)=>
  ({
    query(stateName) {
      if (angular.isArray((stateName))) {
        angular.forEach(stateName, state => $translatePartialLoader.addPart(state));
      } else {
        $translatePartialLoader.addPart(stateName);
      }
      return $translate.refresh();
    }
  })

]);

'use strict';

Application.Services.factory('Translations', ['$translatePartialLoader', '$translate', function ($translatePartialLoader, $translate) {
  return ({
    query (stateName) {
      if (angular.isArray((stateName))) {
        angular.forEach(stateName, state => $translatePartialLoader.addPart(state));
      } else {
        $translatePartialLoader.addPart(stateName);
      }
      return $translate.refresh();
    }
  });
}]);

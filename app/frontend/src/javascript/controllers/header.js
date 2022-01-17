'use strict';

Application.Controllers.controller('HeaderController', ['$scope', '$rootScope', '$state', 'settingsPromise',
  function ($scope, $rootScope, $state, settingsPromise) {
    $scope.aboutPage = ($state.current.name === 'app.public.about');

    $rootScope.$on('$stateChangeStart', function (event, toState) {
      $scope.aboutPage = (toState.name === 'app.public.about');
    });

    /**
     * Returns the current state of the public registration setting (allowed/blocked).
     */
    $scope.registrationEnabled = function () {
      return settingsPromise.public_registrations === 'true';
    };
  }
]);

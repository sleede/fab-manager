'use strict';

Application.Controllers.controller('HeaderController', ['$scope', '$transitions', '$state', 'settingsPromise',
  function ($scope, $transitions, $state, settingsPromise) {
    $scope.aboutPage = ($state.current.name === 'app.public.about');

    $transitions.onStart({}, function (trans) {
      $scope.aboutPage = (trans.$to().name === 'app.public.about');
    });

    /**
     * Returns the current state of the public registration setting (allowed/blocked).
     */
    $scope.registrationEnabled = function () {
      return settingsPromise.public_registrations === 'true';
    };
  }
]);

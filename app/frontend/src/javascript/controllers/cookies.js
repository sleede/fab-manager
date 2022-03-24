'use strict';

/**
 * Controller used for the cookies consent modal
 */
Application.Controllers.controller('CookiesController', ['$scope', '$cookies', 'Setting',
  function ($scope, $cookies, Setting) {
    /* PUBLIC SCOPE */

    // the acceptation state (undefined if no decision was made until now)
    $scope.cookiesState = undefined;

    // link pointed by "learn more"
    $scope.learnMoreUrl = 'https://www.cookiesandyou.com/';

    // add a cookie to the browser, saving the user choice to refuse cookies
    $scope.declineCookies = function () {
      const expires = moment().add(13, 'months').toDate();
      $cookies.put('fab-manager-cookies-consent', 'decline', { expires });
      readCookie();
    };

    // add a cookie to the browser, saving the user choice to accept cookies.
    // Then enable the analytics
    $scope.acceptCookies = function () {
      const expires = moment().add(13, 'months').toDate();
      $cookies.put('fab-manager-cookies-consent', 'accept', { expires });
      readCookie();
      GTM.enableAnalytics(Fablab.trackingId);
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      readCookie();
      // if the privacy policy was defined, redirect the user to it when clicking on "read more"
      Setting.get({ name: 'privacy_body' }, data => {
        if (data.setting.value) {
          $scope.learnMoreUrl = '#!/privacy-policy';
        }
      });
      // if the tracking ID was not set in the settings, only functional cookies will be set, so user consent is not required
      if (!Fablab.trackingId) $scope.cookiesState = 'ignore';
    };

    const readCookie = function () {
      $scope.cookiesState = $cookies.get('fab-manager-cookies-consent');
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

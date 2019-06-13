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

    // current user wallet
    $scope.declineCookies = function () {
      const expires = moment().add(13, 'months').toDate();
      $cookies.put('fab-manager-cookies-consent', 'decline', { expires });
      readCookie();
    };

    // current wallet transactions
    $scope.acceptCookies = function () {
      const expires = moment().add(13, 'months').toDate();
      $cookies.put('fab-manager-cookies-consent', 'accept', { expires });
      readCookie();
      // enable tracking using code provided by google analytics
      /* eslint-disable */
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

      ga('create', Fablab.gaId, 'auto');
      ga('send', 'pageview');
      /* eslint-enable */
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      readCookie();
      // if the privacy policy was defined, redirect the user to it
      Setting.get({ name: 'privacy_body' }, data => {
        if (data.setting.value) {
          $scope.learnMoreUrl = '#!/privacy-policy';
        }
      });
      // if the GA_ID environment variable was not set, only functional cookies will be set, so user consent is not required
      $scope.cookiesState = 'ignore';
    };

    const readCookie = function () {
      $scope.cookiesState = $cookies.get('fab-manager-cookies-consent');
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

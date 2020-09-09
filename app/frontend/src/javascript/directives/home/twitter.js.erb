/* global twitterFetcher */

/**
 * This directive will show the last tweet.
 * Usage: <twitter />
 */
Application.Directives.directive('twitter', ['Setting',
  function (Setting) {
    return ({
      restrict: 'E',
      templateUrl: 'home/twitter.html',
      link ($scope, element, attributes) {
        // Twitter username
        $scope.twitterName = null;

        // constructor
        const initialize = function () {
          Setting.get({ name: 'twitter_name' }, function (data) {
            $scope.twitterName = data.setting.value;
            if ($scope.twitterName) {
              const configProfile = {
                'profile': { 'screenName': $scope.twitterName },
                'domId': 'twitter',
                'maxTweets': 1,
                'enableLinks': true,
                'showUser': false,
                'showTime': true,
                'showImages': false,
                'showRetweet': true,
                'showInteraction': false,
                'lang': Fablab.locale
              };
              twitterFetcher.fetch(configProfile);
            }
          })
        };

        // !!! MUST BE CALLED AT THE END of the directive
        return initialize();
      }
    });
  }
]);

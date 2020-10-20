/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Controllers.controller('DashboardController', ['$scope', 'memberPromise', 'SocialNetworks', function ($scope, memberPromise, SocialNetworks) {
  // Current user's profile
  $scope.user = memberPromise;

  // List of social networks associated with this user and toggle 'show all' state
  $scope.social = {
    showAllLinks: false,
    networks: SocialNetworks
  };

  /* PRIVATE SCOPE */

  /**
   * Kind of constructor: these actions will be realized first when the controller is loaded
   */
  const initialize = () => $scope.social.networks = filterNetworks();

  /**
   * Filter social network or website that are associated with the profile of the user provided in promise
   * and return the filtered networks
   * @return {Array}
   */
  var filterNetworks = function () {
    const networks = [];
    for (let network of Array.from(SocialNetworks)) {
      if ($scope.user.profile[network] && ($scope.user.profile[network].length > 0)) {
        networks.push(network);
      }
    }
    return networks;
  };

  // !!! MUST BE CALLED AT THE END of the controller
  return initialize();
}

]);

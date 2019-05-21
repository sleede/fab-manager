/**
 * Controller used in abuses management page
 */
Application.Controllers.controller('AbusesController', ['$scope', '$state', 'Abuse', 'abusesPromise', 'dialogs', 'growl', '_t',
  function ($scope, $state, Abuse, abusesPromise, dialogs, growl, _t) {
    /* PUBLIC SCOPE */

    // List of all reported abuses
    $scope.abuses = [];

    /**
     * Callback handling a click on the ✓ button: confirm before delete
     */
    $scope.confirmProcess = function (abuseId) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('manage_abuses.confirmation_required'),
                msg: _t('manage_abuses.report_will_be_destroyed')
              };
            }
          }
        },
        function () { // cancel confirmed
          Abuse.remove({ id: abuseId }, function () { // successfully canceled
            growl.success(_t('manage_abuses.report_removed'));
            Abuse.query({}, function (abuses) {
              $scope.abuses = abuses.abuses.filter(a => a.signaled_type === 'Project');
            });
          }
          , function () { // error while canceling
            growl.error(_t('manage_abuses.failed_to_remove'));
          });
        }
      );
    };

    /* PRIVATE SCOPE */
    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {
      // we display only abuses related to projects
      $scope.abuses = abusesPromise.abuses.filter(a => a.signaled_type === 'Project');
    };

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }
]);

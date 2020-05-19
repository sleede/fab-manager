/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
Application.Controllers.controller('OpenAPIClientsController', ['$scope', 'clientsPromise', 'growl', 'OpenAPIClient', 'dialogs', '_t', 'Member', 'uiTourService',
  function ($scope, clientsPromise, growl, OpenAPIClient, dialogs, _t, Member, uiTourService) {
    /* PUBLIC SCOPE */

    // clients list
    $scope.clients = clientsPromise;
    $scope.order = null;
    $scope.clientFormVisible = false;
    $scope.client = {};

    /**
     * Show the name edition form for a new client
     */
    $scope.createClient = function () {
      $scope.clientFormVisible = true;
      $scope.client = {};
    };

    /**
     * Change the order criterion to the one provided
     * @param orderBy {string} ordering criterion
     */
    $scope.setOrder = function (orderBy) {
      if ($scope.order === orderBy) {
        return $scope.order = `-${orderBy}`;
      } else {
        return $scope.order = orderBy;
      }
    };

    /**
     * Reset the name ot its original value and close the edition form
     */
    $scope.cancelEdit = function () {
      $scope.client.name = $scope.clientOriginalName;
      $scope.clientFormVisible = false;
    };

    $scope.saveClient = function (client) {
      if (client.id != null) {
        OpenAPIClient.update({ id: client.id }, { open_api_client: client }, function (clientResp) {
          client = clientResp;
          return growl.success(_t('app.admin.open_api_clients.client_successfully_updated'));
        });
      } else {
        OpenAPIClient.save({ open_api_client: client }, function (client) {
          $scope.clients.push(client);
          return growl.success(_t('app.admin.open_api_clients.client_successfully_created'));
        });
      }

      $scope.clientFormVisible = false;
      $scope.client = {};
    };

    $scope.editClient = function (client) {
      $scope.clientFormVisible = true;
      $scope.client = client;
      $scope.clientOriginalName = client.name;
    };

    $scope.deleteClient = index =>
      dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('app.admin.open_api_clients.confirmation_required'),
              msg: _t('app.admin.open_api_clients.do_you_really_want_to_delete_this_open_api_client')
            };
          }
        }
      }
      , () =>
        OpenAPIClient.delete({ id: $scope.clients[index].id }, function () {
          $scope.clients.splice(index, 1);
          return growl.success(_t('app.admin.open_api_clients.client_successfully_deleted'));
        })
      );

    $scope.resetToken = client =>
      dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('app.admin.open_api_clients.confirmation_required'),
              msg: _t('app.admin.open_api_clients.do_you_really_want_to_revoke_this_open_api_access')
            };
          }
        }
      }
      , () =>
        OpenAPIClient.resetToken({ id: client.id }, {}, function (clientResp) {
          client.token = clientResp.token;
          return growl.success(_t('app.admin.open_api_clients.access_successfully_revoked'));
        })
      );

    /**
     * Setup the feature-tour for the admin/open_api_clients page.
     * This is intended as a contextual help (when pressing F1)
     */
    $scope.setupOpenAPITour = function () {
      // get the tour defined by the ui-tour directive
      const uitour = uiTourService.getTourByName('open-api');
      uitour.createStep({
        selector: 'body',
        stepId: 'welcome',
        order: 0,
        title: _t('app.admin.tour.open_api.welcome.title'),
        content: _t('app.admin.tour.open_api.welcome.content'),
        placement: 'bottom',
        orphan: true
      });
      uitour.createStep({
        selector: '.heading .documentation-button',
        stepId: 'doc',
        order: 1,
        title: _t('app.admin.tour.open_api.doc.title'),
        content: _t('app.admin.tour.open_api.doc.content'),
        placement: 'bottom'
      });
      uitour.createStep({
        selector: 'body',
        stepId: 'conclusion',
        order: 2,
        title: _t('app.admin.tour.conclusion.title'),
        content: _t('app.admin.tour.conclusion.content'),
        placement: 'bottom',
        orphan: true
      });
      // on tour end, save the status in database
      uitour.on('ended', function () {
        if (uitour.getStatus() === uitour.Status.ON && $scope.currentUser.profile.tours.indexOf('open-api') < 0) {
          Member.completeTour({ id: $scope.currentUser.id }, { tour: 'open-api' }, function (res) {
            $scope.currentUser.profile.tours = res.tours;
          });
        }
      });
      // if the user has never seen the tour, and if the display behavior is not configured to manual triggering only, show the tour now
      if (Fablab.featureTourDisplay !== 'manual' && $scope.currentUser.profile.tours.indexOf('open-api') < 0) {
        uitour.start();
      }
    };

    /* PRIVATE SCOPE */

    /**
     * Kind of constructor: these actions will be realized first when the controller is loaded
     */
    const initialize = function () {};

    // !!! MUST BE CALLED AT THE END of the controller
    return initialize();
  }

]);

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
Application.Controllers.controller('OpenAPIClientsController', ['$scope', 'clientsPromise', 'growl', 'OpenAPIClient', 'dialogs', '_t',
  function ($scope, clientsPromise, growl, OpenAPIClient, dialogs, _t) {
  /* PUBLIC SCOPE */

    // clients list
    $scope.clients = clientsPromise
    $scope.order = null
    $scope.clientFormVisible = false
    $scope.client = {}

    $scope.toggleForm = () => $scope.clientFormVisible = !$scope.clientFormVisible

    // Change the order criterion to the one provided
    // @param orderBy {string} ordering criterion
    // 
    $scope.setOrder = function (orderBy) {
      if ($scope.order === orderBy) {
        return $scope.order = `-${orderBy}`
      } else {
        return $scope.order = orderBy
      }
    }

    $scope.saveClient = function (client) {
      if (client.id != null) {
        OpenAPIClient.update({ id: client.id }, { open_api_client: client }, function (clientResp) {
          client = clientResp
          return growl.success(_t('client_successfully_updated'))
        })
      } else {
        OpenAPIClient.save({ open_api_client: client }, function (client) {
          $scope.clients.push(client)
          return growl.success(_t('client_successfully_created'))
        })
      }

      $scope.clientFormVisible = false
      $scope.clientForm.$setPristine()
      return $scope.client = {}
    }

    $scope.editClient = function (client) {
      $scope.clientFormVisible = true
      return $scope.client = client
    }

    $scope.deleteClient = index =>
      dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('confirmation_required'),
              msg: _t('do_you_really_want_to_delete_this_open_api_client')
            }
          }
        }
      }
      , () =>
        OpenAPIClient.delete({ id: $scope.clients[index].id }, function () {
          $scope.clients.splice(index, 1)
          return growl.success(_t('client_successfully_deleted'))
        })
      )

    return $scope.resetToken = client =>
      dialogs.confirm({
        resolve: {
          object () {
            return {
              title: _t('confirmation_required'),
              msg: _t('do_you_really_want_to_revoke_this_open_api_access')
            }
          }
        }
      }
      , () =>
        OpenAPIClient.resetToken({ id: client.id }, {}, function (clientResp) {
          client.token = clientResp.token
          return growl.success(_t('access_successfully_revoked'))
        })
      )
  }

])

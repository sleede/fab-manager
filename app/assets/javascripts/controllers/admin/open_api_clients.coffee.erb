Application.Controllers.controller "OpenAPIClientsController", ["$scope", 'clientsPromise', 'growl', 'OpenAPIClient', 'dialogs', '_t'
, ($scope, clientsPromise, growl, OpenAPIClient, dialogs, _t) ->



  ### PUBLIC SCOPE ###

  ## clients list
  $scope.clients = clientsPromise
  $scope.order = null
  $scope.clientFormVisible = false
  $scope.client = {}

  $scope.toggleForm = ->
    $scope.clientFormVisible = !$scope.clientFormVisible


  # Change the order criterion to the one provided
  # @param orderBy {string} ordering criterion
  ##
  $scope.setOrder = (orderBy)->
    if $scope.order == orderBy
      $scope.order = '-'+orderBy
    else
      $scope.order = orderBy

  $scope.saveClient = (client)->
    if client.id?
      OpenAPIClient.update { id: client.id }, open_api_client: client, (clientResp)->
        client = clientResp
        growl.success(_t('client_successfully_updated'))
    else
      OpenAPIClient.save open_api_client: client, (client)->
        $scope.clients.push client
        growl.success(_t('client_successfully_created'))


    $scope.clientFormVisible = false
    $scope.clientForm.$setPristine()
    $scope.client = {}

  $scope.editClient = (client)->
    $scope.clientFormVisible = true
    $scope.client = client

  $scope.deleteClient = (index)->
    dialogs.confirm
      resolve:
        object: ->
          title: _t('confirmation_required')
          msg: _t('do_you_really_want_to_delete_this_open_api_client')
    , ->
      OpenAPIClient.delete { id: $scope.clients[index].id }, ->
        $scope.clients.splice(index, 1)
        growl.success(_t('client_successfully_deleted'))

  $scope.resetToken = (client)->
    dialogs.confirm
      resolve:
        object: ->
          title: _t('confirmation_required')
          msg: _t('do_you_really_want_to_revoke_this_open_api_access')
    , ->
      OpenAPIClient.resetToken { id: client.id }, {}, (clientResp)->
        client.token = clientResp.token
        growl.success(_t('access_successfully_revoked'))


]

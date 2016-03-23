'use strict'

Application.Services.factory 'dialogs', ["$uibModal", ($uibModal) ->
    confirm: (options, success, error)->
      defaultOpts =
        templateUrl: '<%= asset_path "shared/confirm_modal.html" %>'
        size: 'sm'
        resolve:
          object: ->
            title: 'Titre de confirmation'
            msg: 'Message de confirmation'
        controller: ['$scope', '$uibModalInstance', '$state', 'object', ($scope, $uibModalInstance, $state, object) ->
          $scope.object = object
          $scope.ok = (info) ->
            $uibModalInstance.close( info )
          $scope.cancel = ->
            $uibModalInstance.dismiss('cancel')
        ]
      angular.extend(defaultOpts, options) if angular.isObject options
      $uibModal.open defaultOpts
      .result['finally'](null).then (info)->
        if angular.isFunction(success)
          success(info)
      , (reason)->
        if angular.isFunction(error)
          error(reason)
  ]

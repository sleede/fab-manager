'use strict';

Application.Services.factory('dialogs', ['$uibModal', function ($uibModal) {
  return ({
    confirm (options, success, error) {
      const defaultOpts = {
        templateUrl: '/shared/confirm_modal.html',
        size: 'sm',
        resolve: {
          object () {
            return {
              title: 'Titre de confirmation',
              msg: 'Message de confirmation'
            };
          }
        },
        controller: ['$scope', '$uibModalInstance', '$state', 'object', function ($scope, $uibModalInstance, $state, object) {
          $scope.object = object;
          $scope.ok = function (info) { $uibModalInstance.close(info); };
          $scope.cancel = function () { $uibModalInstance.dismiss('cancel'); };
        }]
      };
      if (angular.isObject(options)) { angular.extend(defaultOpts, options); }
      return $uibModal.open(defaultOpts)
        .result.finally(null).then(function (info) {
          if (angular.isFunction(success)) {
            return success(info);
          }
        }
        , function (reason) {
          if (angular.isFunction(error)) {
            return error(reason);
          }
        });
    }
  });
}]);

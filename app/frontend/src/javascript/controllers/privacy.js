'use strict';

Application.Controllers.controller('PrivacyController', ['$scope', 'Setting', function ($scope, Setting) {
  /* PUBLIC SCOPE */

  Setting.get({ name: 'privacy_body' }, data => { $scope.privacyBody = data.setting; });

  Setting.get({ name: 'privacy_dpo' }, data => { $scope.privacyDpo = data.setting; });
}
]);

/* eslint-disable
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

Application.Controllers.controller('AboutController', ['$scope', 'Setting', 'CustomAsset', function ($scope, Setting, CustomAsset) {
  /* PUBLIC SCOPE */

  Setting.get({ name: 'about_title' }, data => $scope.aboutTitle = data.setting);

  Setting.get({ name: 'about_body' }, data => $scope.aboutBody = data.setting);

  Setting.get({ name: 'about_contacts' }, data => $scope.aboutContacts = data.setting);

  // retrieve the CGU
  CustomAsset.get({ name: 'cgu-file' }, cgu => $scope.cgu = cgu.custom_asset);

  // retrieve the CGV
  return CustomAsset.get({ name: 'cgv-file' }, cgv => $scope.cgv = cgv.custom_asset);
}
]);

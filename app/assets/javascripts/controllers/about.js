'use strict'

Application.Controllers.controller "AboutController", ['$scope', 'Setting', 'CustomAsset', ($scope, Setting, CustomAsset)->

  ### PUBLIC SCOPE ###

  Setting.get { name: 'about_title'}, (data)->
    $scope.aboutTitle = data.setting

  Setting.get { name: 'about_body'}, (data)->
    $scope.aboutBody = data.setting

  Setting.get { name: 'about_contacts'}, (data)->
    $scope.aboutContacts = data.setting

  # retrieve the CGU
  CustomAsset.get {name: 'cgu-file'}, (cgu) ->
    $scope.cgu = cgu.custom_asset

  # retrieve the CGV
  CustomAsset.get {name: 'cgv-file'}, (cgv) ->
    $scope.cgv = cgv.custom_asset
]

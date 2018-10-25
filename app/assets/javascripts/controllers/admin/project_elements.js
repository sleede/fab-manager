'use strict'

Application.Controllers.controller "ProjectElementsController", ["$scope", "$state", 'Component', 'Licence', 'Theme', 'componentsPromise', 'licencesPromise', 'themesPromise'
, ($scope, $state, Component, Licence, Theme, componentsPromise, licencesPromise, themesPromise) ->

  ## Materials list (plastic, wood ...)
  $scope.components = componentsPromise

  ## Licences list (Creative Common ...)
  $scope.licences = licencesPromise

  ## Themes list (cooking, sport ...)
  $scope.themes = themesPromise

  ##
  # Saves a new component / Update an existing material to the server (form validation callback)
  # @param data {Object} component name
  # @param [data] {number} component id, in case of update
  ##
  $scope.saveComponent = (data, id) ->
    if id?
      Component.update {id: id}, data
    else
      Component.save data, (resp)->
        $scope.components[$scope.components.length-1].id = resp.id



  ##
  # Deletes the component at the specified index
  # @param index {number} component index in the $scope.components array
  ##
  $scope.removeComponent = (index) ->
    Component.delete $scope.components[index]
    $scope.components.splice(index, 1)



  ##
  # Creates a new empty entry in the $scope.components array
  ##
  $scope.addComponent = ->
    $scope.inserted =
      name: ''
    $scope.components.push($scope.inserted)



  ##
  # Removes the newly inserted but not saved component / Cancel the current component modification
  # @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
  # @param index {number} component index in the $scope.components array
  ##
  $scope.cancelComponent = (rowform, index) ->
    if $scope.components[index].id?
      rowform.$cancel()
    else
      $scope.components.splice(index, 1)



  ##
  # Saves a new theme / Update an existing theme to the server (form validation callback)
  # @param data {Object} theme name
  # @param [data] {number} theme id, in case of update
  ##
  $scope.saveTheme = (data, id) ->
    if id?
      Theme.update {id: id}, data
    else
      Theme.save data, (resp)->
        $scope.themes[$scope.themes.length-1].id = resp.id



  ##
  # Deletes the theme at the specified index
  # @param index {number} theme index in the $scope.themes array
  ##
  $scope.removeTheme = (index) ->
    Theme.delete $scope.themes[index]
    $scope.themes.splice(index, 1)



  ##
  # Creates a new empty entry in the $scope.themes array
  ##
  $scope.addTheme = ->
    $scope.inserted =
      name: ''
    $scope.themes.push($scope.inserted)



  ##
  # Removes the newly inserted but not saved theme / Cancel the current theme modification
  # @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
  # @param index {number} theme index in the $scope.themes array
  ##
  $scope.cancelTheme = (rowform, index) ->
    if $scope.themes[index].id?
      rowform.$cancel()
    else
      $scope.themes.splice(index, 1)



  ##
  # Saves a new licence / Update an existing licence to the server (form validation callback)
  # @param data {Object} licence name and description
  # @param [data] {number} licence id, in case of update
  ##
  $scope.saveLicence = (data, id) ->
    if id?
      Licence.update {id: id}, data
    else
      Licence.save data, (resp)->
        $scope.licences[$scope.licences.length-1].id = resp.id



  ##
  # Deletes the licence at the specified index
  # @param index {number} licence index in the $scope.licences array
  ##
  $scope.removeLicence = (index) ->
    Licence.delete $scope.licences[index]
    $scope.licences.splice(index, 1)



  ##
  # Creates a new empty entry in the $scope.licences array
  ##
  $scope.addLicence = ->
    $scope.inserted =
      name: ''
      description: ''
    $scope.licences.push($scope.inserted)



  ##
  # Removes the newly inserted but not saved licence / Cancel the current licence modification
  # @param rowform {Object} see http://vitalets.github.io/angular-xeditable/
  # @param index {number} licence index in the $scope.licences array
  ##
  $scope.cancelLicence = (rowform, index) ->
    if $scope.licences[index].id?
      rowform.$cancel()
    else
      $scope.licences.splice(index, 1)
]

/* eslint-disable
    camelcase,
    no-return-assign,
    no-undef,
*/
// TODO: This file was created by bulk-decaffeinate.
// Fix any style issues and re-enable lint.
/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
'use strict';

/* COMMON CODE */

// list of supported authentication methods
const METHODS = {
  DatabaseProvider: 'local_database',
  OAuth2Provider: 'o_auth2'
};

/**
 * Iterate through the provided array and return the index of the requested element
 * @param elements {Array<{id:*}>}
 * @param id {*} id of the element to retrieve in the list
 * @returns {number} index of the requested element, in the provided array
 */
const findIdxById = function (elements, id) {
  return (elements.map(function (elem) { return elem.id; })).indexOf(id);
};

/**
 * Page listing all authentication providers
 */
Application.Controllers.controller('AuthentificationController', ['$scope', '$state', '$rootScope', 'dialogs', 'growl', 'authProvidersPromise', 'AuthProvider', '_t',
  function ($scope, $state, $rootScope, dialogs, growl, authProvidersPromise, AuthProvider, _t) {
  /* PUBLIC SCOPE */

    // full list of authentication providers
    $scope.providers = authProvidersPromise;

    /**
     * Translate the classname into an explicit textual message
     * @param type {string} Ruby polymorphic model classname
     * @returns {string}
     */
    $scope.getType = function (type) {
      const text = METHODS[type];
      if (typeof text !== 'undefined') {
        return _t(`app.admin.members.authentication_form.${text}`);
      } else {
        return _t('app.admin.members.authentication_form.unknown') + type;
      }
    };

    /**
     * Translate the status string into an explicit textual message
     * @param status {string} active | pending | previous
     * @returns {string}
     */
    $scope.getState = function (status) {
      switch (status) {
        case 'active': return _t('app.admin.members.authentication_form.active');
        case 'pending': return _t('app.admin.members.authentication_form.pending');
        case 'previous': return _t('app.admin.members.authentication_form.previous_provider');
        default: return _t('app.admin.members.authentication_form.unknown') + status;
      }
    };

    /**
     * Ask for confirmation then delete the specified provider
     * @param providers {Array} full list of authentication providers
     * @param provider {Object} provider to delete
     */
    $scope.destroyProvider = function (providers, provider) {
      dialogs.confirm(
        {
          resolve: {
            object () {
              return {
                title: _t('app.admin.members.authentication_form.confirmation_required'),
                msg: _t('app.admin.members.authentication_form.do_you_really_want_to_delete_the_TYPE_authentication_provider_NAME', { TYPE: $scope.getType(provider.providable_type), NAME: provider.name })
              };
            }
          }
        },
        function () {
          // the admin has confirmed, delete
          AuthProvider.delete(
            { id: provider.id },
            function () {
              providers.splice(findIdxById(providers, provider.id), 1);
              growl.success(_t('app.admin.members.authentication_form.authentication_provider_successfully_deleted'));
            },
            function () { growl.error(_t('app.admin.members.authentication_form.an_error_occurred_unable_to_delete_the_specified_provider')); }
          );
        }
      );
    };
  }

]);

/**
 * Page to add a new authentication provider
 */
Application.Controllers.controller('NewAuthenticationController', ['$scope', '$state', 'growl',
  function ($scope, $state, growl) {
    /**
     * Shows a success message forwarded from a child react component
     */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };

    /**
     * Callback triggered by react components
     */
    $scope.onError = function (message) {
      growl.error(message);
    };

    $scope.cancel = function () { $state.go('app.admin.members'); };
  }
]);

/**
 * Page to edit an already added authentication provider
 */
Application.Controllers.controller('EditAuthenticationController', ['$scope', '$state', 'growl', 'providerPromise',
  function ($scope, $state, growl, providerPromise) {
  // parameters of the currently edited authentication provider
    $scope.provider = cleanProvider(providerPromise);

    /**
     * Shows a success message forwarded from a child react component
     */
    $scope.onSuccess = function (message) {
      growl.success(message);
    };

    /**
     * Callback triggered by react components
     */
    $scope.onError = function (message) {
      growl.error(message);
    };

    $scope.cancel = function () { $state.go('app.admin.members'); };

    // prepare the provider for the react-hook-form
    function cleanProvider (provider) {
      delete provider.$promise;
      delete provider.$resolved;
      return provider;
    }
  }
]);

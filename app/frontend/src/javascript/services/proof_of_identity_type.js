'use strict';

Application.Services.factory('ProofOfIdentityType', ['$resource', function ($resource) {
  return $resource('/api/proof_of_identity_types/:id',
    { id: '@id' }, {
      update: {
        method: 'PUT'
      }
    }
  );
}]);

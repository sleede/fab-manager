'use strict';

Application.Services.factory('helpers', ['AuthService', function (AuthService) {
  return ({
    getAmountToPay (price, walletAmount) {
      if (walletAmount > price) { return 0; } else { return price - walletAmount; }
    },

    isUserValidationRequired (settings, type) {
      return settings.user_validation_required === 'true' &&
        settings.user_validation_required_list &&
        settings.user_validation_required_list.split(',').includes(type);
    },

    isUserValidated (user) {
      return !!(user?.validated_at);
    },

    isUserValidatedByType (user, settings, type) {
      return AuthService.isAuthorized(['admin', 'manager']) || (!this.isUserValidationRequired(settings, type) || (
        this.isUserValidationRequired(settings, type) && this.isUserValidated(user)));
    }
  });
}]);

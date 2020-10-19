Application.Services.service('es', ['esFactory', function (esFactory) {
  return esFactory({ host: window.location.origin });
}]);

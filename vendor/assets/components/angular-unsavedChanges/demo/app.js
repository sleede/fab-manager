angular
    .module('app', ['unsavedChanges', 'ngRoute'])
    .config(['$routeProvider', 'unsavedWarningsConfigProvider',
        function($routeProvider, unsavedWarningsConfigProvider) {

            $routeProvider
                .when('/page1', {
                    templateUrl: 'page1.html'
                })
                .when('/page2', {
                    templateUrl: 'page2.html'
                })
                .otherwise({
                    redirectTo: '/page1'
                });

            unsavedWarningsConfigProvider.useTranslateService = false;
        }
    ])
    .controller('demoCtrl', function($scope) {
        $scope.user = {
            name: '',
            email: ''
        };
        $scope.demoFormSubmit = function() {
            $scope.message = 'Form Saved';
            $scope.user = {};
        };
    });

Application.Directives.directive('textSetting', ['Setting', 'growl', '_t',
  function (Setting, growl, _t) {
    return ({
      restrict: 'E',
      scope: {
        name: '@',
        label: '@',
        settings: '=',
        classes: '@',
        faIcon: '@',
        placeholder: '@',
        required: '<',
        type: '@',
        maxLength: '@',
        minLength: '@',
        readOnly: '<'
      },
      templateUrl: '/admin/settings/text.html',
      link ($scope, element, attributes) {
        // if type is not specified, use text as default
        if (typeof $scope.type === 'undefined') {
          $scope.type = 'text';
        }
        // 'required' default to true
        if (typeof $scope.required === 'undefined') {
          $scope.required = true;
        }
        // The setting
        $scope.setting = {
          name: $scope.name,
          value: $scope.settings[$scope.name]
        };

        $scope.$watch(`settings.${$scope.name}`, function (newValue, oldValue, scope) {
          if (newValue !== oldValue) {
            $scope.setting.value = newValue;
          }
        });

        /**
         * Callback to save the setting value to the database
         * @param setting {{value:*, name:string}} note that the value will be stringified
         */
        $scope.save = function (setting) {
          const { value } = setting;

          Setting.update(
            { name: setting.name },
            { value },
            function () {
              growl.success(_t('app.admin.settings.customization_of_SETTING_successfully_saved', { SETTING: _t(`app.admin.settings.${setting.name}`) }));
              $scope.settings[$scope.name] = value;
            },
            function (error) {
              if (error.status === 304) return;

              if (error.status === 423) {
                growl.error(_t('app.admin.settings.error_SETTING_locked', { SETTING: _t(`app.admin.settings.${setting.name}`) }));
                return;
              }

              growl.error(_t('app.admin.settings.an_error_occurred_saving_the_setting'));
              console.log(error);
            }
          );
        };
      }
    });
  }
]);

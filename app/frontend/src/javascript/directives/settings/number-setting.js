Application.Directives.directive('numberSetting', ['Setting', 'growl', '_t',
  function (Setting, growl, _t) {
    return ({
      restrict: 'E',
      scope: {
        name: '@',
        label: '@',
        settings: '=',
        classes: '@',
        faIcon: '@',
        helperText: '@',
        min: '@',
        required: '<'
      },
      templateUrl: '../../../../templates/admin/settings/number.html',
      link ($scope, element, attributes) {
        // The setting
        $scope.setting = {
          name: $scope.name,
          value: parseInt($scope.settings[$scope.name], 10)
        };

        /**
         * Callback to save the setting value to the database
         * @param setting {{value:*, name:string}} note that the value will be stringified
         */
        $scope.save = function (setting) {
          let value;
          if (typeof setting.value === 'number') {
            value = setting.value.toString();
          } else {
            ({ value } = setting);
          }

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

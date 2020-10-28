Application.Directives.directive('booleanSetting', ['Setting', 'growl', '_t',
  function (Setting, growl, _t) {
    return ({
      restrict: 'E',
      scope: {
        name: '@',
        label: '@',
        settings: '=',
        classes: '@',
        onBeforeSave: '='
      },
      templateUrl: '/admin/settings/boolean.html',
      link ($scope, element, attributes) {
        // The setting
        $scope.setting = {
          name: $scope.name,
          value: ($scope.settings[$scope.name] === 'true')
        };

        // ID of the html input
        $scope.id = `setting-${$scope.setting.name}`;

        /**
         * This will update the value when the user toggles the switch button
         * @param checked {Boolean}
         * @param event {string}
         * @param id {string}
         */
        $scope.toggleSetting = (checked, event, id) => {
          setTimeout(() => {
            $scope.setting.value = checked;
            $scope.$apply();
          }, 50);
        };

        /**
         * This will force the component to update, and the child react component to re-render
         */
        $scope.refreshComponent = () => {
          $scope.$apply();
        };

        /**
         * Callback to save the setting value to the database
         * @param setting {{value:*, name:string}} note that the value will be stringified
         */
        $scope.save = function (setting) {
          if (typeof $scope.onBeforeSave === 'function') {
            const res = $scope.onBeforeSave(setting);
            if (res && _.isFunction(res.then)) {
              // res is a promise, wait for it before proceed
              res.then(function (success) {
                if (success) saveValue(setting);
                else resetValue();
              }, function () {
                resetValue();
              });
            } else {
              if (res) saveValue(setting);
              else resetValue();
            }
          } else {
            saveValue(setting);
          }
        };

        /* PRIVATE SCOPE */

        /**
         * Save the setting's new value in DB
         * @param setting
         */
        const saveValue = function (setting) {
          const value = setting.value.toString();

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

        /**
         * Reset the value of the setting to its original state (when the component loads)
         */
        const resetValue = function () {
          $scope.setting.value = $scope.settings[$scope.name] === 'true';
        };
      }
    });
  }
]);

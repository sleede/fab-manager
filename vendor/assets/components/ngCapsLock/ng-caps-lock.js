(function () {
  'use strict';

  angular.module('ngCapsLock', []).run(['$rootScope', '$document', '$timeout', function ($rootScope, $document, $timeout) {

    var bindingForAppleDevice = function () {
      $document.bind("keydown", function (event) {
        if (event.keyCode === 20) { setCapsLockOn(true); }
      });

      $document.bind("keyup", function (event) {
        if (event.keyCode === 20) { setCapsLockOn(false); }
      });

      $document.bind("keypress", function (event) {
        var code = event.charCode || event.keyCode;
        var shift = event.shiftKey;

        if (code > 96 && code < 123) { setCapsLockOn(false); }
        if (code > 64 && code < 91 && !shift) { setCapsLockOn(true); }
      });
    };

    var bindingForOthersDevices = function () {
      var isKeyPressed = true;

      $document.bind("keydown", function (event) {
        if (!isKeyPressed && event.keyCode === 20) {
          isKeyPressed = true;
          if ($rootScope.isCapsLockOn != null) { setCapsLockOn(!$rootScope.isCapsLockOn); }
        }
      });

      $document.bind("keyup", function (event) {
        if (event.keyCode === 20) { isKeyPressed = false; }
      });

      $document.bind("keypress", function (event) {
        var code = event.charCode || event.keyCode;
        var shift = event.shiftKey;

        if (code > 96 && code < 123) { setCapsLockOn(shift); }
        if (code > 64 && code < 91) { setCapsLockOn(!shift); }
      });
    };

    if (/Mac|iPad|iPhone|iPod/.test(navigator.platform)) {
      bindingForAppleDevice();
    } else {
      bindingForOthersDevices();
    }

    var setCapsLockOn = function (isOn) {
      $timeout(function () {
        $rootScope.isCapsLockOn = isOn;
      });
    };

  }]);

}());

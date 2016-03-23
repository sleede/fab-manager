'use strict';

Application.Directives.directive('bsJasnyFileinput', [function(){
  return {
    require : ['ngModel'],
    link : function($scope, elm, attrs, requiredCtrls){
      var ngModelCtrl = requiredCtrls[0];
      var fileinput = elm.parents('[data-provides=fileinput]');
      var filetypeRegex = attrs.bsJasnyFileinput;
      fileinput.on('clear.bs.fileinput', function(e){
        if(ngModelCtrl){
          ngModelCtrl.$setViewValue(null);
          ngModelCtrl.$setPristine();
          $scope.$apply();
        }
      });
      fileinput.on('change.bs.fileinput', function(e, files){
        if(ngModelCtrl){
          if(files){
            ngModelCtrl.$setViewValue(files.result);
          } else {
            ngModelCtrl.$setPristine();
          }

          // TODO: ne marche pas pour filetype
          if (filetypeRegex) {
            if(files && typeof files.type !== "undefined" && files.type.match(new RegExp(filetypeRegex)))
              ngModelCtrl.$setValidity('filetype', true);
            else
              ngModelCtrl.$setValidity('filetype', false);
          };
        }
        $scope.$apply();
      });
    }
  }
}]);

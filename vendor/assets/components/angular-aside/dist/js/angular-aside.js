
/*!
 * angular-aside - v1.3.2
 * https://github.com/dbtek/angular-aside
 * 2015-11-17
 * Copyright (c) 2015 İsmail Demirbilek
 * License: MIT
 */

(function() {
  'use strict';

  /**
   * @ngdoc overview
   * @name ngAside
   * @description
   * Main module for aside component.
   * @function
   * @author İsmail Demirbilek
   */
  angular.module('ngAside', ['ui.bootstrap.modal']);
})();

(function() {
  'use strict';

  angular.module('ngAside')
    /**
     * @ngdoc service
     * @name ngAside.services:$aside
     * @description
     * Factory to create a uibModal instance to use it as aside. It simply wraps $uibModal by overriding open() method and sets a class on modal window.
     * @function
     */
    .factory('$aside', ['$uibModal', function($uibModal) {
      var defaults = this.defaults = {
        placement: 'left'
      };

      var asideFactory = {
        // override open method
        open: function(config) {
          var options = angular.extend({}, defaults, config);
          // check placement is set correct
          if(['left', 'right', 'bottom', 'top'].indexOf(options.placement) === -1) {
            options.placement = defaults.placement;
          }
          var vertHoriz = ['left', 'right'].indexOf(options.placement) === -1 ? 'vertical' : 'horizontal';
          // set aside classes
          options.windowClass  = 'ng-aside ' + vertHoriz + ' ' + options.placement + (options.windowClass ? ' ' + options.windowClass : '');
          delete options.placement
          return $uibModal.open(options);
        }
      };

      // create $aside as extended $uibModal
      var $aside = angular.extend({}, $uibModal, asideFactory);
      return $aside;
    }]);
})();

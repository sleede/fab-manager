/*!
 * angular-aside - v1.3.2
 * https://github.com/dbtek/angular-aside
 * 2015-11-17
 * Copyright (c) 2015 İsmail Demirbilek
 * License: MIT
 */
!function(){"use strict";angular.module("ngAside",["ui.bootstrap.modal"])}(),function(){"use strict";angular.module("ngAside").factory("$aside",["$uibModal",function(a){var b=this.defaults={placement:"left"},c={open:function(c){var d=angular.extend({},b,c);-1===["left","right","bottom","top"].indexOf(d.placement)&&(d.placement=b.placement);var e=-1===["left","right"].indexOf(d.placement)?"vertical":"horizontal";return d.windowClass="ng-aside "+e+" "+d.placement+(d.windowClass?" "+d.windowClass:""),delete d.placement,a.open(d)}},d=angular.extend({},a,c);return d}])}();
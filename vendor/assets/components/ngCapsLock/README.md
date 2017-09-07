# ngCapsLock

ngCapsLock is a module for [AngularJS](http://angularjs.org/) to detect if caps-lock is on/off.

Getting Started
---------------

 * Download ngCapsLock or install it with [Bower](http://bower.io/) via `bower install ng-caps-lock`
 * Include the script tag on your page after the AngularJS script tags

        <script type='text/javascript' src='path/to/angular.min.js'></script>
        <script type='text/javascript' src='path/to/ng-caps-lock.min.js'></script>

 * Ensure that your application module specifies `ngCapsLock` as a dependency:

        angular.module('myApp', ['ngCapsLock']);

 * Use the property `isCapsLockOn` on a `ng-show` directive.

        <p class="caps-lock-alert" ng-show='isCapsLockOn'>Caps lock is on</p>

License
-------

ngCapsLock is licensed under the MIT license. See the LICENSE file for more details.

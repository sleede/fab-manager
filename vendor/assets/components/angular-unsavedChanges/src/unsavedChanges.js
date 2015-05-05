'use strict';
/*jshint globalstrict: true*/
/*jshint undef:false */

angular.module('unsavedChanges', ['resettable'])

.provider('unsavedWarningsConfig', function() {

    var _this = this;

    // defaults
    var logEnabled = false;
    var useTranslateService = true;
    var routeEvent = ['$locationChangeStart', '$stateChangeStart'];
    var navigateMessage = 'You will lose unsaved changes if you leave this page';
    var reloadMessage = 'You will lose unsaved changes if you reload this page';

    Object.defineProperty(_this, 'navigateMessage', {
        get: function() {
            return navigateMessage;
        },
        set: function(value) {
            navigateMessage = value;
        }
    });

    Object.defineProperty(_this, 'reloadMessage', {
        get: function() {
            return reloadMessage;
        },
        set: function(value) {
            reloadMessage = value;
        }
    });

    Object.defineProperty(_this, 'useTranslateService', {
        get: function() {
            return useTranslateService;
        },
        set: function(value) {
            useTranslateService = !! (value);
        }
    });

    Object.defineProperty(_this, 'routeEvent', {
        get: function() {
            return routeEvent;
        },
        set: function(value) {
            if (typeof value === 'string') value = [value];
            routeEvent = value;
        }
    });
    Object.defineProperty(_this, 'logEnabled', {
        get: function() {
            return logEnabled;
        },
        set: function(value) {
            logEnabled = !! (value);
        }
    });

    this.$get = ['$injector',
        function($injector) {

            function translateIfAble(message) {
                if ($injector.has('$translate') && useTranslateService) {
                    return $injector.get('$translate').instant(message);
                } else {
                    return false;
                }
            }

            var publicInterface = {
                // log function that accepts any number of arguments
                // @see http://stackoverflow.com/a/7942355/1738217
                log: function() {
                    if (console.log && logEnabled && arguments.length) {
                        var newarr = [].slice.call(arguments);
                        if (typeof console.log === 'object') {
                            log.apply.call(console.log, console, newarr);
                        } else {
                            console.log.apply(console, newarr);
                        }
                    }
                }
            };

            Object.defineProperty(publicInterface, 'useTranslateService', {
                get: function() {
                    return useTranslateService;
                }
            });

            Object.defineProperty(publicInterface, 'reloadMessage', {
                get: function() {
                    return translateIfAble(reloadMessage) || reloadMessage;
                }
            });

            Object.defineProperty(publicInterface, 'navigateMessage', {
                get: function() {
                    return translateIfAble(navigateMessage) || navigateMessage;
                }
            });

            Object.defineProperty(publicInterface, 'routeEvent', {
                get: function() {
                    return routeEvent;
                }
            });

            Object.defineProperty(publicInterface, 'logEnabled', {
                get: function() {
                    return logEnabled;
                }
            });

            return publicInterface;
        }
    ];
})

.service('unsavedWarningSharedService', ['$rootScope', 'unsavedWarningsConfig', '$injector', '$window',
    function($rootScope, unsavedWarningsConfig, $injector, $window) {

        // Controller scopped variables
        var _this = this;
        var allForms = [];
        var areAllFormsClean = true;
        var removeFunctions = [];

        // @note only exposed for testing purposes.
        this.allForms = function() {
            return allForms;
        };

        // Check all registered forms
        // if any one is dirty function will return true

        function allFormsClean() {
            areAllFormsClean = true;
            angular.forEach(allForms, function(item, idx) {
                unsavedWarningsConfig.log('Form : ' + item.$name + ' dirty : ' + item.$dirty);
                if (item.$dirty) {
                    areAllFormsClean = false;
                }
            });
            return areAllFormsClean; // no dirty forms were found
        }

        // adds form controller to registered forms array
        // this array will be checked when user navigates away from page
        this.init = function(form) {
            if (allForms.length === 0) setup();
            unsavedWarningsConfig.log("Registering form", form);
            allForms.push(form);
        };

        this.removeForm = function(form) {
            var idx = allForms.indexOf(form);

            // this form is not present array
            // @todo needs test coverage
            if (idx === -1) return;

            allForms.splice(idx, 1);
            unsavedWarningsConfig.log("Removing form from watch list", form);

            if (allForms.length === 0) tearDown();
        };

        function tearDown() {
            unsavedWarningsConfig.log('No more forms, tearing down');
            angular.forEach(removeFunctions, function(fn) {
                fn();
            });
            removeFunctions = [];
            $window.onbeforeunload = null;
        }

        // Function called when user tries to close the window
        this.confirmExit = function() {
            if (!allFormsClean()) return unsavedWarningsConfig.reloadMessage;
            $rootScope.$broadcast('resetResettables');
            tearDown();
        };

        // bind to window close
        // @todo investigate new method for listening as discovered in previous tests

        function setup() {
            unsavedWarningsConfig.log('Setting up');

            $window.onbeforeunload = _this.confirmExit;

            var eventsToWatchFor = unsavedWarningsConfig.routeEvent;

            angular.forEach(eventsToWatchFor, function(aEvent) {
                //calling this function later will unbind this, acting as $off()
                var removeFn = $rootScope.$on(aEvent, function(event, next, current) {
                    unsavedWarningsConfig.log("user is moving with " + aEvent);
                    // @todo this could be written a lot cleaner!
                    if (!allFormsClean()) {
                        unsavedWarningsConfig.log("a form is dirty");
                        if (!confirm(unsavedWarningsConfig.navigateMessage)) {
                            unsavedWarningsConfig.log("user wants to cancel leaving");
                            event.preventDefault(); // user clicks cancel, wants to stay on page
                        } else {
                            unsavedWarningsConfig.log("user doesn't care about loosing stuff");
                            $rootScope.$broadcast('resetResettables');
                        }
                    } else {
                        unsavedWarningsConfig.log("all forms are clean");
                    }

                });
                removeFunctions.push(removeFn);
            });
        }
    }
])

.directive('unsavedWarningClear', ['unsavedWarningSharedService',
    function(unsavedWarningSharedService) {
        return {
            scope: {},
            require: '^form',
            priority: 10,
            link: function(scope, element, attrs, formCtrl) {
                element.bind('click', function(event) {
                    formCtrl.$setPristine();
                });

            }
        };
    }
])

.directive('unsavedWarningForm', ['unsavedWarningSharedService', '$rootScope',
    function(unsavedWarningSharedService, $rootScope) {
        return {
            scope: {},
            require: '^form',
            link: function(scope, formElement, attrs, formCtrl) {

                // @todo refactor, temp fix for issue #22
                // where user might use form on element inside a form
                // we shouldnt need isolate scope on this, but it causes the tests to fail
                // traverse up parent elements to find the form.
                // we need a form element since we bind to form events: submit, reset
                var count = 0;
                while(formElement[0].tagName !== 'FORM' && count < 3) {
                    count++;
                    formElement = formElement.parent();
                }
                if(count >= 3) {
                    throw('unsavedWarningForm must be inside a form element');
                }

                // register this form
                unsavedWarningSharedService.init(formCtrl);

                // bind to form submit, this makes the typical submit button work
                // in addition to the ability to bind to a seperate button which clears warning
                formElement.bind('submit', function(event) {
                    if (formCtrl.$valid) {
                        formCtrl.$setPristine();
                    }
                });

                // bind to form submit
                // developers can hook into resetResettables to do
                // do things like reset validation, present messages, etc.
                formElement.bind('reset', function(event) {
                    event.preventDefault();
                    
                    // trigger resettables within this form or element 
                    var resettables = angular.element(formElement[0].querySelector('[resettable]'));
                    if(resettables.length) {
                        scope.$apply(resettables.triggerHandler('resetResettables'));    
                    }

                    // sets for back to valid and pristine states
                    formCtrl.$setPristine();
                });

                // @todo check destroy on clear button too?
                scope.$on('$destroy', function() {
                    unsavedWarningSharedService.removeForm(formCtrl);
                });
            }
        };
    }
]);


/**
 * --------------------------------------------
 * resettable models adapted from vitalets lazy model
 * @see https://github.com/vitalets/lazy-model/
 *
 * The main difference is that we DO set the model value
 * as the user changes the inputs. However we provide a hook
 * to reset the model to original value. This we can then
 * broadcast on from reset which triggers resettable to revert
 * to original value.
 * --------------------------------------------
 *
 * @note we don't create a seperate scope so the model value
 * is still available onChange within the controller scope. 
 * This fixes https://github.com/facultymatt/angular-unsavedChanges/issues/19
 *
 */
angular.module('resettable', [])

.directive('resettable', ['$parse', '$compile', '$rootScope',
    function($parse, $compile, $rootScope) {

        return {
            restrict: 'A',
            link: function postLink(scope, elem, attr, ngModelCtrl) {

                var setter, getter, originalValue;

                // save getters and setters and store the original value.
                attr.$observe('ngModel', function(newValue) {
                    getter = $parse(attr.ngModel);
                    setter = getter.assign;
                    originalValue = getter(scope);
                });

                // reset our form to original value
                var resetFn = function() {
                    setter(scope, originalValue);
                };

                elem.on('resetResettables', resetFn);

                // @note this doesn't work if called using
                // $rootScope.on() and $rootScope.$emit() pattern
                var removeListenerFn = scope.$on('resetResettables', resetFn);
                scope.$on('$destroy', removeListenerFn);

            }
        };
    }
]);

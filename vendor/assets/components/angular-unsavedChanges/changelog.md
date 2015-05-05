# Changelog

Versioning follows [http://semver.org/](http://semver.org/), ie: MAJOR.MINOR.PATCH. Major version 0 is initial development. Minor versions may be backwards incompatible.

### 0.2.3-alpha.2 

__angular-unsavedChanges will remain in alpha until the e2e tests pass, as per https://github.com/facultymatt/angular-unsavedChanges/issues/25__


- Fixed support for angular translate > 2.0.0 [#14](https://github.com/facultymatt/angular-unsavedChanges/pull/14), thanks to @dmytroyarmak
- Fixed issue where removeFunctions were not being cleared properly [#21](https://github.com/facultymatt/angular-unsavedChanges/pull/21), thanks to @dmytroyarmak
- fix unit tests for jasmine 2.0
- add test for isolate scope on form element
- require form on element or parent, fixes #22
- use $window instead of window
- update to angular 1.3, closes #23



### 0.2.3-alpha.1

- Removed form and model dependencies and code from `resettable` directive. We weren't using the get form functionality anyhow. 
- Moved form reset events out of the resettable directive to prevent them from being called multiple times unnecessarily.
- Fixed bug where resettable functions were piling up and not properly being removed when scope was destroyed. 
- Module now consistently broadcasts `resetResettables` from $rootScope when user resets form or dismisses alert dialog. (previously this was sometimes called twice)


### 0.2.2-alpha.1

Added `$rootScope.$emit('resetResettables')` to form directive on reset. This allows hooking into reset without using resettable directive.

### 0.2.1-alpha.1

Form not emits `$rootScope.$emit('resetResettables')` when reset. This allows developers to do fancy things like reset validation or message user on form reset. Previously `resetResettables` was only called when use dismissed changes with alert dialog. 

### 0.2.0-alpha.1

This is an alpha release because the tests are not complete and there might be issues with scopes on directives.

**Breaking Changes**

- Removed lazy-model integration in favor of `resettable` directive. Adding to inputs will cause their model values to be reset. Unlike the lazy-model directive the model value settings is not deferred until form submit. This avoids conflicts with validation. 

### 0.1.1

**Features**

- routeEvent can be an array with multiple events to listen for. If user sets to string will convert to array. Defaults to `['$locationChangeStart' ,'$stateChangeStart']` which supports ui router by default.


### 0.1.0

**Features**

- Add `lazy-model` directive, and change `clear` buttons to `type="reset"` which allows for resetting the model to original values. Furthermore values are only persisted to model if user submits valid form.
- Only set pristine when clearing changes if form is valid. (https://github.com/facultymatt/angular-unsavedChanges/commit/26cd981397f3e1e637280e3778aa80708821dab4). The lazy-model form reset hook handles resetting the value. 
- Directive now removes onbeforeunload and route change listeners if no registered forms exist on the page. (https://github.com/facultymatt/angular-unsavedChanges/commit/58cad5401656bb806183d0a42c8b81bf1fbeeac6)

**Breaking Changes**

- Change getters and setters to user NJO (native javascript objects). This means that insated of setting `provider.setUseTranslateService(true)` you can natively set `provider.useTranslateService = true`. This may seem like semantics but if follows one of angulars core principals. 

### 0.0.3

**Tests**

- Add full set of unit and e2e tests

**Features**

- Add config option for custom messages
- Add support for uiRouter state change event via. config
- Add support for Angular Translate
- Add custom logging method for development

**Chores**

- Add module to bower. 

**Breaking Changes**

- Changed name from `mm.unsavedChanges` to `unsavedChanges`


### 0.0.2 and below

Offical changelog was not maintained for these versions.  

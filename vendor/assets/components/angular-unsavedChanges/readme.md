# An AngularJS directive for forms that alerts user of unsaved changes.

_Dev Note: This module is still in development. However it's used in many of my production projects so it can be considered stable and battle tested._

This directive will alert users when they navigate away from a page where a form has unsaved changes. It will be triggered in all situations where form data would be lost:

- when user clicks a link
- when user navigates with forward / back button
- when user swipes (iOS)
- when user refreshes the page

In addition this module: 

- Works with multiple forms on the same page
- Provides a button to disregard unsaved changes
- Works with Angular Translate module
- Has configurable reload and navigate messages
- Works with uiRouter by default by listeneing for `$locationChangeStart` and `$stateChangeStart` 
- Can be configured to listen for any event

## How it Works

The directive binds to `locationChangeStart` and `window.onbeforeunload`. When these events happen all registered froms are checked if they are dirty. The module defers to the forms `$dirty` property as a single source of truth. If dirty, the user is alerted. Disregarding changes resets the form and sets pristine.  

## Basic Usage

- Install from bower using `$ bower install angular-unsavedChanges --save`.
- Include the JS, for example `<script src="bower_components/angular-unsavedChanges/dist/unsavedChanges.js"></script>`.
- Include in your app, for example: `angular.module('app', ['unsavedChanges', 'anotherDirective'])`
- Add attribute to your form, `unsaved-warning-form`
- That's it!


## API

### Directives 
The module provides three directives for use. 

#### unsaved-warning-form 
Add to forms you want to register with directive. The module will only listen when forms are registered. 

```
<form name="testForm" unsaved-warning-form>
</form>
```

Optionally, you can add to an element within a form:

```
<form name="testForm">
	<div unsaved-warning-form>
	</div>
</form>
```

When used in this way, it must be no more then 3 levels nested within parent form.


#### unsaved-warning-clear 
Add to button or link that will disregard changes, preventing the messaging when user tries to navigate. Note that button type should be `reset`.

```
<form name="testForm" unsaved-warning-form>
    <input name="test" type="text" ng-model="test"/>
    <button type="submit"></button>
    <button type="reset" unsaved-warning-clear></button>
</form>
```

#### resettable
Add to inputs that use `ng-model` to reset model values when user dismisses changes or clicks the `unsaved-warning-clear` button.

```
<input name="email" ng-model="email" resettable />
```

Note that if you have multiple forms on the page, only the model values inside the form which was reset will be effected. 

On page change or reload, all model values will be effected. 


### Provider Configuration 
A number of options can be configured. The module uses the `Object.defineProperty` pattern. This avoids the need for custom getters and setters and allows us to treat configuration as pure JS objects. 

#### useTranslateService
Defaults to `true`. Will use translate service if available. It's safe to leave this set to `true`, even when not using the translate service, because the module still checks that the service exists. 

```
unsavedWarningsConfigProvider.useTranslateService = true;
```

#### logEnabled
Defaults to `false`. Uses the services internal logging method for debugging.  

```
unsavedWarningsConfigProvider.logEnabled = true;
```

#### routeEvent
Defaults to `['$locationChangeStart' ,'$stateChangeStart']` which supports ui router by default.

```
unsavedWarningsConfigProvider.routeEvent = '$stateChangeStart';
```

#### navigateMessage
Set custom message displayed when user navigates. If using translate this will be the key to translate. 
```
unsavedWarningsConfigProvider.navigateMessage = "Custom Navigate Message";
```

#### reloadMessage
Set custom message displayed when user refreshes the page. If using translate this will be the key to translate. 
```
unsavedWarningsConfigProvider.reloadMessage = "Custom Reload Message";
```


## Gotchas / Known Bugs

*** Known issue: sometimes the form is removed from expected scope. Ie: in your controller `$scope.formName` no longer works. You might need to access `$scope.$$childTail.formName`. This will be fixed in furture versions.


## Demo / Dev

To try the demo run `npm install` && `bower install` && `grunt connect`. The browser should open [http://127.0.0.1:9001/demo](http://127.0.0.1:9001/demo).


## Test

Note you need to manually change the paths in `index.html` and `karam-unit.conf` to point to the `dist` version for final testing. Make sure to run `$ grunt` first. 

__End 2 End Testing__
Because of the alert / event driven nature of this module it made the most sense to rely on e2e tests. (also its hard to interact with alerts via unit tests).

To run the e2e tests do the following: 

- Install Protractor as per directions here: [https://github.com/angular/protractor](https://github.com/angular/protractor)
- Start selenium server: `webdriver-manager start` (or use other selenium methods as per Protractor documentation.)
- Run `$ grunt test:e2e`


__Unit Tests__

- Run `$ grunt test:unit` OR `$ grunt test`


## Build

Run `$ grunt` to lint and minify the code. Also strips console logs.


## License

The MIT License (MIT)

Copyright (c) 2013-2014 Matt Miller

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

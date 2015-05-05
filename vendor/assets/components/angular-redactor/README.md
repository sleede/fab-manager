angular-redactor
================

Angular Redactor is an angular directive for the Redactor editor.  http://imperavi.com/redactor/


Usage
--------------

1. Include the redactor libraries
2. In your angular application register angular-redactor as a dependency.
3. Add the necessary html to view the editor.

Registration

```js

// Angular Registration
angular.module('app', ['angular-redactor']);

```

Bare Minimum Html
```html
<textarea ng-model="content" redactor></textarea>
```

With Options
```html
<textarea ng-model="content" redactor="{buttons: ['formatting', '|', 'bold', 'italic']}" cols="30" rows="10"></textarea>
```

You can pass options directly to Redactor by specifying them as the value of the `redactor` attribute.


Check out the demo folder where you can see a working example.  https://github.com/TylerGarlick/angular-redactor/tree/master/demo



Bower Installation
--------------
```js
bower install angular-redactor
```

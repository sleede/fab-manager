# ng-FitText.js

### ng-FitText.js makes font-sizes flexible. Use this AngularJS directive in your fluid or responsive layout to achieve scalable headlines that fill the width of a parent element.

This is a rework of the original jQuery plugin which can be found here: https://github.com/davatron5000/FitText.js.

### Install and Inclusion

Grab it with Bower: `bower install ngFitText`

Include it in your AngularJS application

```javascript
var myApp = angular.module('myApp', ['ngFitText']);
```

### Implementation

```html
<!-- basic implementation -->
<h1 data-fittext>FitText</h1>

<!-- dynamic content -->
<h1 data-fittext ></h1>

<!-- setting a minimum font size -->
<h1 data-fittext data-fittext-min="10">FitText</h1>

<!-- minimum font size inherited from CSS -->
<h1 data-fittext data-fittext-min="inherit">FitText</h1>

<!-- setting a maximum font size -->
<h1 data-fittext data-fittext-max="10">FitText</h1>

<!-- maximum font size inherited from CSS -->
<h1 data-fittext data-fittext-max="inherit">FitText</h1>

<!-- combination of restrictions -->
<h1 data-fittext data-fittext-min="10" data-fittext-max="inherit">FitText</h1>
<h1 data-fittext data-fittext-min="inherit" data-fittext-max="100">FitText</h1>
<h1 data-fittext data-fittext-min="10" data-fittext-max="100">FitText</h1>

<!-- block child elements will share smallest font size -->
<div data-fittext>
  <div>Short line</div>
  <div>Font size of this element will be used</div>
  <div>Short</div>
</div>

<!-- inline child elements will behave as a single line of text -->
<span data-fittext>
  <span>Single</span>
  <span> line of text</span>
  <span> spans 100% width</span>
</span>

<!-- Custom fonts may take to load in. A delay can be specified before size is initially calculated -->
<h1 data-fittext data-fittext-load-delay="500">Custom font</h1>

<!-- Custom fonts may ooze out of element; this is the same as the original compressor attr -->
<h1 data-fittext=".9">Custom font</h1>
```

### FitText Config Provider

Because MODULARIZATION, this module doesn't come with debounce functionality included. Instead you will need to specify the functionality in the `fitTextConfigProvider`:

```javascript
module.config(['fitTextConfigProvider', function(fitTextConfigProvider) {
  fitTextConfigProvider.config = {
    debounce: _.debounce,               // include a vender function like underscore or lodash
    debounce: function(a,b,c) {         // specify your own function
      var d;return function(){var e=this,f=arguments;clearTimeout(d),d=setTimeout(function(){d=null,c||a.apply(e,f)},b),c&&!d&&a.apply(e,f)}
    },
    delay: 1000,                        // debounce delay
    loadDelay: 10,                      // global default delay before initial calculation
    compressor: 1,                      // global default calculation multiplier
    min: 0,                             // global default min
    max: Number.POSITIVE_INFINITY       // global default max
  };
}]);
```

### Changelog

#### [v4.1.0](https://github.com/patrickmarabeas/ng-FitText.js/releases/tag/v4.1.0)
+ Replace `'initial'` value with more semantic `'inherit'`
+ Both `data-fittext-min` and `data-fittext-max` can use the inherited CSS value by using `'inherit'`

#### [v4.0.0](https://github.com/patrickmarabeas/ng-FitText.js/releases/tag/v4.0.0)
+ `data-fittext-max` can now take `'initial'` as a value to use inherited CSS value. This allows for PX, EM or REM to be used.
+ Line heights are preserved
+ Display property is now preserved
+ New lines no longer need to be specified with an attribute
+ `ng-model` was mistakenly used for `ng-bind` - No longer need to use both `ng-model` and `{{}}` for dynamic values
+ Minified version now delivered via Bower
+ Config provider namespaced to avoid conflicts

#### [v3.0.0](https://github.com/patrickmarabeas/ng-FitText.js/releases/tag/v3.0.0)
+ Element now defaults to 100% width
+ Compressor now fine tunes from this point
+ Debounce functionality now needs to be passed in via fitTextConfigProvider

#### < v2.4.0
+ Specifying a value for data-fittext allows you to fine tune the text size. Defaults to 1. Increasing this number (ie 1.5) will resize the text more aggressively. Decreasing this number (ie 0.5) will reduce the aggressiveness of resize. data-fittext-min and data-fittext-max allow you to set upper and lower limits.
+ The element needs to either be a block element or an inline-block element with a width specified (% or px).
+ Font sizes can be limited with `data-fittext-max` and `data-fittext-max`
+ Debouncing addded

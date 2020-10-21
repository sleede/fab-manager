// This is a demonstration of using react components inside an angular.js 1.x app
// TODO remove this

import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { react2angular } from 'react2angular';

class MyComponent extends Component {
  render () {
    return <div>
      <p>FooBar: {this.props.fooBar}</p>
      <p>Baz: {this.props.baz}</p>
    </div>;
  }
}

MyComponent.propTypes = {
  fooBar: PropTypes.number,
  baz: PropTypes.string
};

Application.Components.component('myComponent', react2angular(MyComponent));

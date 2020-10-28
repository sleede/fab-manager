// This is a demonstration of using react components inside an angular.js 1.x app
// TODO remove this

import { IApplication } from "./application";
declare var Application: IApplication;

import React from 'react';
import { react2angular } from 'react2angular';

interface MyComponentProps {
  fooBar: number,
  baz: string
}

const MyComponent: React.FC<MyComponentProps> = ({ fooBar, baz }) => {
  return (
    <div>
      <p>FooBar: {fooBar}</p>
      <p>Baz: {baz}</p>
    </div>
  );
}

Application.Components.component('myComponent', react2angular(MyComponent, ['fooBar', 'baz']));

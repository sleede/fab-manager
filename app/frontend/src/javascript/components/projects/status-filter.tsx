import React from 'react';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';

declare const Application: IApplication;

/**
 * To do documentation
 */

export const StatusFilter = () => {
  return (
    <p> Hello </p>
  );
};

Application.Components.component('statusFilter', react2angular(StatusFilter, []));

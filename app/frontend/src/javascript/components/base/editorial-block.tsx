import React from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { FabButton } from './fab-button';

declare const Application: IApplication;

/**
 * Display a editorial text block with an optional cta button
 */
export const EditorialBlock: React.FC = () => {
  return (
    <div className='editorial-block'>
      <div dangerouslySetInnerHTML={{ __html: '<h3>Lorem ipsum</h3><p>sit amet consectetur adipisicing elit. Voluptates, possimus excepturi deleniti sed pariatur sint.</p>' }}></div>
      <FabButton className='is-main'>CTA label</FabButton>
    </div>
  );
};

const EditorialBlockWrapper: React.FC = (props) => {
  return (
    <Loader>
      <EditorialBlock {...props} />
    </Loader>
  );
};

Application.Components.component('editorialBlock', react2angular(EditorialBlockWrapper, []));

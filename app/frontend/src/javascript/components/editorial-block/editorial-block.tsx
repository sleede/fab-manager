import React from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { FabButton } from '../base/fab-button';

declare const Application: IApplication;

interface EditorialBlockProps {
  text: string,
  cta?: string,
  url?: string
}

/**
 * Display a editorial text block with an optional cta button
 */
export const EditorialBlock: React.FC<EditorialBlockProps> = ({ text, cta, url }) => {
  /** Link to url from props */
  const linkTo = (): void => {
    window.location.href = url;
  };

  return (
    <div className={`editorial-block ${cta?.length > 25 ? 'long-cta' : ''}`}>
      <div dangerouslySetInnerHTML={{ __html: text }}></div>
      {cta && <FabButton className='is-main' onClick={linkTo}>{cta}</FabButton>}
    </div>
  );
};

const EditorialBlockWrapper: React.FC<EditorialBlockProps> = ({ ...props }) => {
  return (
    <Loader>
      <EditorialBlock {...props} />
    </Loader>
  );
};

Application.Components.component('editorialBlock', react2angular(EditorialBlockWrapper, ['text', 'cta', 'url']));

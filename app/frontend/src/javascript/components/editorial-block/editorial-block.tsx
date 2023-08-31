import React from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { SettingValue } from '../../models/setting';

declare const Application: IApplication;

interface EditorialBlockProps {
  text: SettingValue,
  cta?: SettingValue,
  url?: SettingValue
}

/**
 * Display a editorial text block with an optional cta button
 */
export const EditorialBlock: React.FC<EditorialBlockProps> = ({ text, cta, url }) => {
  return (
    <div className={`editorial-block ${(cta as string)?.length > 25 ? 'long-cta' : ''}`}>
      <div dangerouslySetInnerHTML={{ __html: text as string }}></div>
      {cta &&
        <a href={url as string} target="_blank" rel="noopener noreferrer" className='fab-button is-main cta'>{cta}</a>
      }
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

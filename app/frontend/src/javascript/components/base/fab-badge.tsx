import * as React from 'react';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import Icons from '../../../../images/icons.svg';

declare const Application: IApplication;

interface FabBadgeProps {
  icon: string,
  iconWidth: string,
  className?: string,
}

/**
 * Renders a badge (parent needs to be position: relative)
 */
export const FabBadge: React.FC<FabBadgeProps> = ({ icon, iconWidth, className }) => {
  return (
    <div className={`fab-badge ${className || ''}`}>
      <svg viewBox="0 0 24 24" width={iconWidth}>
        <use href={`${Icons}#${icon}`}/>
      </svg>
    </div>
  );
};

const FabBadgeWrapper: React.FC<FabBadgeProps> = ({ icon, iconWidth, className }) => {
  return (
    <Loader>
      <FabBadge icon={icon} iconWidth={iconWidth} className={className} />
    </Loader>
  );
};

Application.Components.component('fabBadge', react2angular(FabBadgeWrapper, ['icon', 'iconWidth', 'className']));

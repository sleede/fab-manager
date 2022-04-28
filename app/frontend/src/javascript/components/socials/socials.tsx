import React from 'react';
import { SocialNetwork } from '../../models/social-network';
import Icons from '../../../../images/social-icons.svg';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';

declare const Application: IApplication;

interface SocialsProps {
  networks: SocialNetwork[]
}

const plop = [{
  name: 'facebook',
  url: 'https://plop.com'
}, {
  name: 'linkedin',
  url: 'https://plop.com'
}];

export const Socials: React.FC<SocialsProps> = ({ networks = plop }) => {
  return (
    <div className='social-icons'>
      {networks.map((network, index) =>
        <a key={index} href={network.url}>
          <img src={`${Icons}#${network.name}`}></img>
        </a>
      )}
    </div>
  );
};

const SocialsWrapper: React.FC<SocialsProps> = (props) => {
  return (
    <Loader>
      <Socials {...props} />
    </Loader>
  );
};
Application.Components.component('socials', react2angular(SocialsWrapper, ['networks']));

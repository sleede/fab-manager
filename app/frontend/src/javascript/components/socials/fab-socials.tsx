import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { FormInput } from '../form/form-input';
import SettingAPI from '../../api/setting';
import { SocialNetwork } from '../../models/social-network';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { SettingName } from '../../models/setting';
import Icons from '../../../../images/social-icons.svg';
import { Trash } from 'phosphor-react';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';

declare const Application: IApplication;

export const FabSocials: React.FC<SocialNetwork> = () => {
  const { t } = useTranslation('shared');

  const { handleSubmit, register, resetField } = useForm();
  const onSubmit = (data) => console.log(data);

  const supportedNetworks = [SettingName.SocialsFacebook, SettingName.SocialsTwitter, SettingName.SocialsViadeo, SettingName.SocialsLinkedin, SettingName.SocialsInstagram, SettingName.SocialsYoutube, SettingName.SocialsVimeo, SettingName.SocialsDailymotion, SettingName.SocialsGithub, SettingName.SocialsEchosciences, SettingName.SocialsPinterest, SettingName.SocialsLastfm, SettingName.SocialsFlickr];

  const [fabNetworks, setFabNetworks] = useState([]);
  useEffect(() => {
    SettingAPI.query(supportedNetworks).then(res => {
      setFabNetworks(Array.from(res, ([name, value]) => ({ name, value })));
    }).catch(error => console.error(error));
  }, []);

  const selectNetwork = (network) => {
    console.log(network);
  };

  const remove = (network) => {
    resetField(network.name);
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div className="social-icons">
        {fabNetworks.map((network, index) =>
          <img key={index} src={`${Icons}#${network.name.replace('socials_', '')}`} onClick={() => selectNetwork(network)}></img>
        )}
      </div>
      {fabNetworks.map((network, index) =>
        <FormInput id={network.name}
                  key={index}
                  register={register}
                  label={network.name.replace('socials_', '')}
                  placeholder={t('app.shared.text_editor.url_placeholder')}
                  addOn={<Trash size={16} />}
                  addOnAction={() => remove(network)} />
      )}
      <FabButton type='submit'
                 className='btn-warning'>
        {t('app.shared.buttons.save')}
      </FabButton>
    </form>
  );
};

const FabSocialsWrapper: React.FC<SocialNetwork> = (props) => {
  return (
    <Loader>
      <FabSocials {...props} />
    </Loader>
  );
};
Application.Components.component('fabSocials', react2angular(FabSocialsWrapper, []));

import React, { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { FormInput } from '../form/form-input';
import SettingAPI from '../../api/setting';
import { supportedNetworks } from '../../models/social-network';
import { IApplication } from '../../models/application';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { SettingName } from '../../models/setting';
import Icons from '../../../../images/social-icons.svg';
import { Trash } from 'phosphor-react';
import { useTranslation } from 'react-i18next';
import { FabButton } from '../base/fab-button';

declare const Application: IApplication;

interface FabSocialsProps {
  show: boolean,
  onError: (message: string) => void,
  onSuccess: (message: string) => void
}

export const FabSocials: React.FC<FabSocialsProps> = ({ show = false, onError, onSuccess }) => {
  const { t } = useTranslation('shared');
  // regular expression to validate the the input fields
  const urlRegex = /^(https?:\/\/)([\da-z.-]+)\.([-a-z\d.]{2,30})([/\w .-]*)*\/?$/;

  const { handleSubmit, register, setValue, formState } = useForm();

  const settingsList = supportedNetworks.map(el => el as SettingName);

  const [fabNetworks, setFabNetworks] = useState([]);
  const [selectedNetworks, setSelectedNetworks] = useState([]);

  useEffect(() => {
    SettingAPI.query(settingsList).then(res => {
      setFabNetworks(Array.from(res, ([name, url]) => ({ name, url })));
    }).catch(error => console.error(error));
  }, []);

  useEffect(() => {
    setSelectedNetworks(fabNetworks.filter(el => el.url !== ''));
  }, [fabNetworks]);

  const onSubmit = (data) => {
    const updatedNetworks = new Map<SettingName, string>();
    Object.keys(data).forEach(key => updatedNetworks.set(key as SettingName, data[key]));
    SettingAPI.bulkUpdate(updatedNetworks).then(res => {
      const errorResults = Array.from(res.values()).filter(item => !item.status);
      if (errorResults.length > 0) {
        onError(t('app.shared.fab_socials.networks_update_error'));
      } else {
        onSuccess(t('app.shared.fab_socials.networks_update_success'));
      }
    });
  };

  const selectNetwork = (network) => {
    setSelectedNetworks([...selectedNetworks, network]);
  };

  const remove = (network) => {
    setSelectedNetworks(selectedNetworks.filter(el => el !== network));
    setValue(network.name, '');
  };

  return (
    <>{show
      ? <div className='social-icons'>
        {fabNetworks.map((network, index) =>
          selectedNetworks.includes(network) &&
          <a key={index} href={network.url} target='_blank' rel="noreferrer">
            <img src={`${Icons}#${network.name}`}></img>
          </a>
        )}
      </div>

      : <form onSubmit={handleSubmit(onSubmit)}>
        <div className='social-icons'>
          {fabNetworks.map((network, index) =>
            !selectedNetworks.includes(network) &&
            <img key={index} src={`${Icons}#${network.name}`} onClick={() => selectNetwork(network)}></img>
          )}
        </div>
        {selectNetwork.length && <div className='social-inputs'>
          {fabNetworks.map((network, index) =>
            selectedNetworks.includes(network) &&
            <FormInput id={network.name}
                      key={index}
                      register={register}
                      rules={{
                        pattern: {
                          value: urlRegex,
                          message: t('app.shared.user_profile_form.website_invalid')
                        }
                      }}
                      formState={formState}
                      defaultValue={network.url}
                      label={network.name}
                      placeholder={t('app.shared.fab_socials.url_placeholder')}
                      icon={<img src={`${Icons}#${network.name}`}></img>}
                      addOn={<Trash size={16} />}
                      addOnAction={() => remove(network)} />
          )}
        </div>}
        <FabButton type='submit'
                  className='btn-warning'>
          {t('app.shared.buttons.save')}
        </FabButton>
      </form>
    }</>
  );
};

const FabSocialsWrapper: React.FC<FabSocialsProps> = (props) => {
  return (
    <Loader>
      <FabSocials {...props} />
    </Loader>
  );
};
Application.Components.component('fabSocials', react2angular(FabSocialsWrapper, ['show', 'onError', 'onSuccess']));

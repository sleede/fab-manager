/**
 * This component displays a summary of the PayZen account keys, with a button triggering the modal to edit them
 */

import React, { useEffect } from 'react';
import { Loader } from './loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../models/application';
import { useTranslation } from 'react-i18next';
import SettingAPI from '../api/setting';
import { SettingName } from '../models/setting';
import { useImmer } from 'use-immer';
import { FabInput } from './fab-input';
import { FabButton } from './fab-button';

declare var Application: IApplication;

interface PayzenSettingsProps {
  onEditKeys: (onlinePaymentModule: {value: boolean}) => void
}

const PAYZEN_HIDDEN = 'testpassword_HiDdEnHIddEnHIdDEnHiDdEnHIddEnHIdDEn';
const payZenPublicSettings: Array<SettingName> = [SettingName.PayZenPublicKey, SettingName.PayZenEndpoint, SettingName.PayZenUsername];
const payZenPrivateSettings: Array<SettingName> = [SettingName.PayZenPassword, SettingName.PayZenHmacKey];
const payZenSettings: Array<SettingName> = payZenPublicSettings.concat(payZenPrivateSettings);
const icons:Map<SettingName, string> = new Map([
  [SettingName.PayZenHmacKey, 'subscript'],
  [SettingName.PayZenPassword, 'key'],
  [SettingName.PayZenUsername, 'user'],
  [SettingName.PayZenEndpoint, 'link'],
  [SettingName.PayZenPublicKey, 'info']
])

const payZenKeys = SettingAPI.query(payZenPublicSettings);
const isPresent = {
  [SettingName.PayZenPassword]: SettingAPI.isPresent(SettingName.PayZenPassword),
  [SettingName.PayZenHmacKey]: SettingAPI.isPresent(SettingName.PayZenHmacKey)
};

export const PayzenSettings: React.FC<PayzenSettingsProps> = ({ onEditKeys }) => {
  const { t } = useTranslation('admin');

  const [settings, updateSettings] = useImmer<Map<SettingName, string>>(new Map(payZenSettings.map(name => [name, ''])));

  useEffect(() => {
    const map = payZenKeys.read();
    for (const setting of payZenPrivateSettings) {
      map.set(setting, isPresent[setting].read() ? PAYZEN_HIDDEN : '');
    }
    updateSettings(map);
  }, []);


  const handleKeysUpdate = (): void => {
    onEditKeys({ value: true });
  }

  return (
    <div className="payzen-settings">
      <h3 className="title">{t('app.admin.invoices.payment.payzen.payzen_keys')}</h3>
       <div className="payzen-keys">
         {payZenSettings.map(setting => {
           return (
             <div className="key-wrapper" key={setting}>
               <label htmlFor={setting}>{t(`app.admin.invoices.payment.payzen.${setting}`)}</label>
               <FabInput defaultValue={settings.get(setting)}
                         id={setting}
                         type={payZenPrivateSettings.indexOf(setting) > -1 ? 'password' : 'text'}
                         icon={<i className={`fas fa-${icons.get(setting)}`} />}
                         readOnly
                         disabled />
             </div>
           );
         })}
         <div className="edit-keys">
           <FabButton className="edit-keys-btn" onClick={handleKeysUpdate}>{t('app.admin.invoices.payment.edit_keys')}</FabButton>
         </div>
       </div>
    </div>
  );
}


const PayzenSettingsWrapper: React.FC<PayzenSettingsProps> = ({ onEditKeys }) => {
  return (
    <Loader>
      <PayzenSettings onEditKeys={onEditKeys} />
    </Loader>
  );
}

Application.Components.component('payzenSettings', react2angular(PayzenSettingsWrapper, ['onEditKeys']));

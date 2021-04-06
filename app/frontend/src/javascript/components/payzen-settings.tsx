/**
 * This component displays a summary of the PayZen account keys, with a button triggering the modal to edit them
 */

import React, { useEffect, useState } from 'react';
import { Loader } from './loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../models/application';
import { useTranslation } from 'react-i18next';
import SettingAPI from '../api/setting';
import { SettingName } from '../models/setting';
import { useImmer } from 'use-immer';
import { FabInput } from './fab-input';
import { FabButton } from './fab-button';
import { FabModal, ModalSize } from './fab-modal';
import { PayZenKeysForm } from './payzen-keys-form';

declare var Application: IApplication;

interface PayzenSettingsProps {

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

export const PayzenSettings: React.FC<PayzenSettingsProps> = ({}) => {
  const { t } = useTranslation('admin');

  const [settings, updateSettings] = useImmer<Map<SettingName, string>>(new Map(payZenSettings.map(name => [name, ''])));
  const [openEditModal, setOpenEditModal] = useState<boolean>(false);
  const [preventConfirm, setPreventConfirm] = useState<boolean>(true);
  const [config, setConfig] = useState<Map<SettingName, string>>(new Map());
  const [errors, setErrors] = useState<string>('');

  useEffect(() => {
    const map = payZenKeys.read();
    for (const setting of payZenPrivateSettings) {
      map.set(setting, isPresent[setting].read() ? PAYZEN_HIDDEN : '');
    }
    updateSettings(map);
  }, []);

  /**
   * Open/closes the modal dialog to edit the payzen keys
   */
  const toggleEditKeysModal = () => {
    setOpenEditModal(!openEditModal);
  }

  const handleUpdateKeys = () => {
    const api = new SettingAPI();
    api.bulkUpdate(config).then(result => {
      if (Array.from(result.values()).filter(item => !item.status).length > 0) {
        setErrors(JSON.stringify(result));
      } else {
        // TODO updateSettings(result);
        toggleEditKeysModal();
      }
    }, reason => {
      setErrors(reason);
    });
  }

  const handleValidPayZenKeys = (payZenKeys: Map<SettingName, string>): void => {
    setConfig(payZenKeys);
    setPreventConfirm(false);
  }

  return (
    <div className="payzen-settings">
      <h3 className="title">{t('app.admin.invoices.payment.payzen.payzen_keys')}</h3>
       <div className="payzen-keys">
         {payZenSettings.map(setting => {
           return (
             <div className="key-wrapper">
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
           <FabButton className="edit-keys-btn" onClick={toggleEditKeysModal}>{t('app.admin.invoices.payment.edit_keys')}</FabButton>
           <FabModal title={t('app.admin.invoices.payment.payzen.payzen_keys')}
                     isOpen={openEditModal}
                     toggleModal={toggleEditKeysModal}
                     width={ModalSize.medium}
                     confirmButton={t('app.admin.invoices.payment.payzen.update_button')}
                     onConfirm={handleUpdateKeys}
                     preventConfirm={preventConfirm}
                     closeButton>
             {errors && <span>{errors}</span>}
             <PayZenKeysForm onValidKeys={handleValidPayZenKeys} />
           </FabModal>
         </div>
       </div>
    </div>
  );
}


const PayzenSettingsWrapper: React.FC<PayzenSettingsProps> = ({}) => {
  return (
    <Loader>
      <PayzenSettings />
    </Loader>
  );
}

Application.Components.component('payzenSettings', react2angular(PayzenSettingsWrapper));

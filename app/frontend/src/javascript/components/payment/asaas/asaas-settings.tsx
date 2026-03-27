import { useEffect, useState } from 'react';
import * as React from 'react';
import { react2angular } from 'react2angular';
import { useTranslation } from 'react-i18next';
import { Loader } from '../../base/loader';
import { FabInput } from '../../base/fab-input';
import { FabButton } from '../../base/fab-button';
import SettingAPI from '../../../api/setting';
import { IApplication } from '../../../models/application';

declare const Application: IApplication;

interface AsaasSettingsProps {
  onEditKeys: (onlinePaymentModule: { value: boolean }) => void,
}

/**
 * Displays the configured Asaas gateway settings.
 */
export const AsaasSettings: React.FC<AsaasSettingsProps> = ({ onEditKeys }) => {
  const { t } = useTranslation('admin');
  const [apiKey, setApiKey] = useState<string>('');
  const [environment, setEnvironment] = useState<string>('sandbox');

  useEffect(() => {
    SettingAPI.get('asaas_api_key').then(setting => setApiKey(setting?.value || '')).catch(() => { /* ignore */ });
    SettingAPI.get('asaas_environment').then(setting => setEnvironment(setting?.value || 'sandbox')).catch(() => { /* ignore */ });
  }, []);

  return (
    <div className="asaas-settings">
      <h3 className="title">{t('app.admin.invoices.asaas_settings.asaas_keys')}</h3>
      <div className="asaas-keys">
        <div className="key-wrapper">
          <label htmlFor="asaas_api_key_readonly">{t('app.admin.invoices.asaas_settings.api_key')}</label>
          <FabInput id="asaas_api_key_readonly" defaultValue={apiKey} type="password" readOnly disabled icon={<i className="fas fa-key" />} />
        </div>
        <div className="key-wrapper">
          <label htmlFor="asaas_environment_readonly">{t('app.admin.invoices.asaas_settings.environment')}</label>
          <FabInput id="asaas_environment_readonly" defaultValue={environment} readOnly disabled icon={<i className="fas fa-server" />} />
        </div>
        <div className="edit-keys">
          <FabButton className="edit-keys-btn" onClick={() => onEditKeys({ value: true })}>{t('app.admin.invoices.asaas_settings.edit_keys')}</FabButton>
        </div>
      </div>
    </div>
  );
};

const AsaasSettingsWrapper: React.FC<AsaasSettingsProps> = ({ onEditKeys }) => (
  <Loader>
    <AsaasSettings onEditKeys={onEditKeys} />
  </Loader>
);

Application.Components.component('asaasSettings', react2angular(AsaasSettingsWrapper, ['onEditKeys']));

import { useEffect, useState } from 'react';
import * as React from 'react';
import { useTranslation } from 'react-i18next';
import { SettingName } from '../../../models/setting';
import SettingAPI from '../../../api/setting';
import { FabInput } from '../../base/fab-input';

interface AsaasKeysFormProps {
  onValidKeys: (keys: Map<SettingName, string>) => void,
  onInvalidKeys: () => void,
}

/**
 * Form used to configure Asaas credentials.
 */
export const AsaasKeysForm: React.FC<AsaasKeysFormProps> = ({ onValidKeys, onInvalidKeys }) => {
  const { t } = useTranslation('admin');
  const [apiKey, setApiKey] = useState<string>('');
  const [environment, setEnvironment] = useState<string>('sandbox');

  useEffect(() => {
    SettingAPI.get('asaas_api_key').then(setting => {
      setApiKey(setting?.value || '');
    }).catch(() => { /* ignore */ });

    SettingAPI.get('asaas_environment').then(setting => {
      setEnvironment(setting?.value || 'sandbox');
    }).catch(() => { /* ignore */ });
  }, []);

  useEffect(() => {
    if (apiKey?.trim()) {
      onValidKeys(new Map<SettingName, string>([['asaas_api_key', apiKey.trim()], ['asaas_environment', environment]]));
    } else {
      onInvalidKeys();
    }
  }, [apiKey, environment]);

  return (
    <div className="asaas-keys-form">
      <p>{t('app.admin.invoices.asaas_keys_form.api_key_info')}</p>
      <label htmlFor="asaas_api_key">{t('app.admin.invoices.asaas_keys_form.api_key')} *</label>
      <FabInput id="asaas_api_key"
        defaultValue={apiKey}
        type="password"
        icon={<i className="fas fa-key" />}
        onChange={(value) => setApiKey(String(value))} />
      <label htmlFor="asaas_environment">{t('app.admin.invoices.asaas_keys_form.environment')}</label>
      <select id="asaas_environment" className="asaas-environment-select" value={environment} onChange={(e) => setEnvironment(e.target.value)}>
        <option value="sandbox">{t('app.admin.invoices.asaas_keys_form.sandbox')}</option>
        <option value="production">{t('app.admin.invoices.asaas_keys_form.production')}</option>
      </select>
    </div>
  );
};

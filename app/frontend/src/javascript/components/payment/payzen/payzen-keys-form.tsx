import React, { ReactNode, useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { enableMapSet } from 'immer';
import { useImmer } from 'use-immer';
import { HtmlTranslate } from '../../base/html-translate';
import { FabInput } from '../../base/fab-input';
import { Loader } from '../../base/loader';
import { SettingName } from '../../../models/setting';
import SettingAPI from '../../../api/setting';
import PayzenAPI from '../../../api/payzen';

enableMapSet();

interface PayzenKeysFormProps {
  onValidKeys: (payZenSettings: Map<SettingName, string>) => void,
  onInvalidKeys: () => void,
}

// all settings related to PayZen that are requested by this form
const payzenSettings: Array<SettingName> = ['payzen_username', 'payzen_password', 'payzen_endpoint', 'payzen_hmac', 'payzen_public_key'];
// settings related to the PayZen REST API (server side)
const restApiSettings: Array<SettingName> = ['payzen_username', 'payzen_password', 'payzen_endpoint', 'payzen_hmac'];

// Prevent multiples call to the payzen keys validation endpoint.
// this cannot be handled by a React state because of their asynchronous nature
let pendingKeysValidation = false;

/**
 * Form to set the PayZen's username, password and public key
 */
const PayzenKeysForm: React.FC<PayzenKeysFormProps> = ({ onValidKeys, onInvalidKeys }) => {
  const { t } = useTranslation('admin');

  // values of the PayZen settings
  const [settings, updateSettings] = useImmer<Map<SettingName, string>>(new Map(payzenSettings.map(name => [name, ''])));
  // Icon of the fieldset for the PayZen's keys concerning the REST API. Used to display if the key is valid.
  const [restApiAddOn, setRestApiAddOn] = useState<ReactNode>(null);
  // Style class for the add-on icon, for the REST API
  const [restApiAddOnClassName, setRestApiAddOnClassName] = useState<'key-invalid' | 'key-valid' | ''>('');
  // Icon of the input field for the PayZen's public key. Used to display if the key is valid.
  const [publicKeyAddOn, setPublicKeyAddOn] = useState<ReactNode>(null);
  // Style class for the add-on icon, for the public key
  const [publicKeyAddOnClassName, setPublicKeyAddOnClassName] = useState<'key-invalid' | 'key-valid' | ''>('');

  /**
   * When the component loads for the first time, initialize the keys with the values fetched from the API (if any)
   */
  useEffect(() => {
    SettingAPI.query(payzenSettings).then(payZenKeys => {
      updateSettings(new Map(payZenKeys));
    }).catch(error => console.error(error));
  }, []);

  /**
   * When the style class for the public key, and the REST API are updated, check if they indicate valid keys.
   * If both are valid, run the 'onValidKeys' callback, else run 'onInvalidKeys'
   */
  useEffect(() => {
    const validClassName = 'key-valid';
    if (publicKeyAddOnClassName === validClassName && restApiAddOnClassName === validClassName) {
      onValidKeys(settings);
    } else {
      onInvalidKeys();
    }
  }, [publicKeyAddOnClassName, restApiAddOnClassName, settings]);

  useEffect(() => {
    testRestApi();
  }, [settings]);

  /**
   * Assign the inputted key to the settings and check if it is valid.
   * Depending on the test result, assign an add-on icon plus a style to notify the user.
   */
  const testPublicKey = (key: string) => {
    if (!key || !key.match(/^[0-9]+:/)) {
      setPublicKeyAddOn(<i className="fa fa-times" />);
      setPublicKeyAddOnClassName('key-invalid');
      return;
    }
    updateSettings(draft => draft.set('payzen_public_key', key));
    setPublicKeyAddOn(<i className="fa fa-check" />);
    setPublicKeyAddOnClassName('key-valid');
  };

  /**
   * Send a test call to the payZen REST API to check if the inputted settings key are valid.
   * Depending on the test result, assign an add-on icon and a style to notify the user.
   */
  const testRestApi = () => {
    const valid: boolean = restApiSettings.map(s => !!settings.get(s))
      .reduce((acc, val) => acc && val, true);

    if (valid && !pendingKeysValidation) {
      pendingKeysValidation = true;
      PayzenAPI.chargeSDKTest(
        settings.get('payzen_endpoint'),
        settings.get('payzen_username'),
        settings.get('payzen_password')
      ).then(result => {
        pendingKeysValidation = false;

        if (result.success) {
          setRestApiAddOn(<i className="fa fa-check" />);
          setRestApiAddOnClassName('key-valid');
        } else {
          setRestApiAddOn(<i className="fa fa-times" />);
          setRestApiAddOnClassName('key-invalid');
        }
      }, () => {
        pendingKeysValidation = false;

        setRestApiAddOn(<i className="fa fa-times" />);
        setRestApiAddOnClassName('key-invalid');
      });
    }
    if (!valid) {
      setRestApiAddOn(<i className="fa fa-times" />);
      setRestApiAddOnClassName('key-invalid');
    }
  };

  /**
   * Assign the inputted key to the given settings
   */
  const setApiKey = (setting: typeof restApiSettings[number]) => {
    return (key: string) => {
      updateSettings(draft => draft.set(setting, key));
    };
  };

  /**
   * Check if an add-on icon must be shown for the API settings
   */
  const hasApiAddOn = () => {
    return restApiAddOn !== null;
  };

  return (
    <div className="payzen-keys-form">
      <div className="payzen-keys-info">
        <HtmlTranslate trKey="app.admin.invoices.payzen_keys_form.payzen_keys_info_html" />
      </div>
      <form name="payzenKeysForm">
        <fieldset>
          <legend>{t('app.admin.invoices.payzen_keys_form.client_keys')}</legend>
          <div className="payzen-public-input">
            <label htmlFor="payzen_public_key">{ t('app.admin.invoices.payzen_keys_form.payzen_public_key') } *</label>
            <FabInput id="payzen_public_key"
              icon={<i className="fas fa-info" />}
              defaultValue={settings.get('payzen_public_key')}
              onChange={testPublicKey}
              addOn={publicKeyAddOn}
              addOnClassName={publicKeyAddOnClassName}
              debounce={200}
              required />
          </div>
        </fieldset>
        <fieldset>
          <legend className={hasApiAddOn() ? 'with-addon' : ''}>
            <span>{t('app.admin.invoices.payzen_keys_form.api_keys')}</span>
            {hasApiAddOn() && <span className={`fieldset-legend--addon ${restApiAddOnClassName || ''}`}>{restApiAddOn}</span>}
          </legend>
          <div className="payzen-api-user-input">
            <label htmlFor="payzen_username">{ t('app.admin.invoices.payzen_keys_form.payzen_username') } *</label>
            <FabInput id="payzen_username"
              type="number"
              icon={<i className="fas fa-user-alt" />}
              defaultValue={settings.get('payzen_username')}
              onChange={setApiKey('payzen_username')}
              debounce={200}
              required />
          </div>
          <div className="payzen-api-password-input">
            <label htmlFor="payzen_password">{ t('app.admin.invoices.payzen_keys_form.payzen_password') } *</label>
            <FabInput id="payzen_password"
              icon={<i className="fas fa-key" />}
              defaultValue={settings.get('payzen_password')}
              onChange={setApiKey('payzen_password')}
              debounce={200}
              required />
          </div>
          <div className="payzen-api-endpoint-input">
            <label htmlFor="payzen_endpoint">{ t('app.admin.invoices.payzen_keys_form.payzen_endpoint') } *</label>
            <FabInput id="payzen_endpoint"
              type="url"
              icon={<i className="fas fa-link" />}
              defaultValue={settings.get('payzen_endpoint')}
              onChange={setApiKey('payzen_endpoint')}
              debounce={200}
              required />
          </div>
          <div className="payzen-api-hmac-input">
            <label htmlFor="payzen_hmac">{ t('app.admin.invoices.payzen_keys_form.payzen_hmac') } *</label>
            <FabInput id="payzen_hmac"
              icon={<i className="fas fa-subscript" />}
              defaultValue={settings.get('payzen_hmac')}
              onChange={setApiKey('payzen_hmac')}
              debounce={200}
              required />
          </div>
        </fieldset>
      </form>
    </div>
  );
};

const PayzenKeysFormWrapper: React.FC<PayzenKeysFormProps> = (props) => {
  return (
    <Loader>
      <PayzenKeysForm {...props} />
    </Loader>
  );
};

export { PayzenKeysFormWrapper as PayzenKeysForm };

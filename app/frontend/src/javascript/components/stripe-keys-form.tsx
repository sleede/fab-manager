/**
 * Form to set the stripe's public and private keys
 */

import React, { ReactNode, useEffect, useState } from 'react';
import { Loader } from './loader';
import { useTranslation } from 'react-i18next';
import SettingAPI from '../api/setting';
import { SettingName } from '../models/setting';
import { FabInput } from './fab-input';
import StripeAPI from '../api/stripe';


interface StripeKeysFormProps {
  onValidKeys: (stripePublic: string, stripeSecret:string) => void
}

const stripeKeys = SettingAPI.query([SettingName.StripePublicKey, SettingName.StripeSecretKey]);

const StripeKeysFormComponent: React.FC<StripeKeysFormProps> = ({ onValidKeys }) => {
  const { t } = useTranslation('admin');

  const [publicKey, setPublicKey] = useState<string>('');
  const [publicKeyAddOn, setPublicKeyAddOn] = useState<ReactNode>(null);
  const [publicKeyAddOnClassName, setPublicKeyAddOnClassName] = useState<string>('');
  const [secretKey, setSecretKey] = useState<string>('');
  const [secretKeyAddOn, setSecretKeyAddOn] = useState<ReactNode>(null);
  const [secretKeyAddOnClassName, setSecretKeyAddOnClassName] = useState<string>('');

  useEffect(() => {
    const keys = stripeKeys.read();
    setPublicKey(keys.get(SettingName.StripePublicKey));
    setSecretKey(keys.get(SettingName.StripeSecretKey));
  }, []);

  useEffect(() => {
    const validClassName = 'key-valid';
    if (publicKeyAddOnClassName === validClassName && secretKeyAddOnClassName === validClassName) {
      onValidKeys(publicKey, secretKey);
    }
  }, [publicKeyAddOnClassName, secretKeyAddOnClassName]);


  /**
   * Send a test call to the Stripe API to check if the inputted public key is valid
   */
  const testPublicKey = (key: string) => {
    if (!key.match(/^pk_/)) {
      setPublicKeyAddOn(<i className="fa fa-times" />);
      setPublicKeyAddOnClassName('key-invalid');
      return;
    }
    StripeAPI.createPIIToken(key, 'test').then(() => {
      setPublicKey(key);
      setPublicKeyAddOn(<i className="fa fa-check" />);
      setPublicKeyAddOnClassName('key-valid');
    }, reason => {
      if (reason.response.status === 401) {
        setPublicKeyAddOn(<i className="fa fa-times" />);
        setPublicKeyAddOnClassName('key-invalid');
      }
    });
  }

  /**
   * Send a test call to the Stripe API to check if the inputted secret key is valid
   */
  const testSecretKey = (key: string) => {
    if (!key.match(/^sk_/)) {
      setSecretKeyAddOn(<i className="fa fa-times" />);
      setSecretKeyAddOnClassName('key-invalid');
      return;
    }
    StripeAPI.listAllCharges(key).then(() => {
      setSecretKey(key);
      setSecretKeyAddOn(<i className="fa fa-check" />);
      setSecretKeyAddOnClassName('key-valid');
    }, reason => {
      if (reason.response.status === 401) {
        setSecretKeyAddOn(<i className="fa fa-times" />);
        setSecretKeyAddOnClassName('key-invalid');
      }
    });
  }

  return (
    <div className="stripe-keys-form">
      <div className="stripe-keys-info" dangerouslySetInnerHTML={{__html: t('app.admin.invoices.payment.stripe_keys_info_html')}} />
      <form name="stripeKeysForm">
        <div className="stripe-public-input">
          <label htmlFor="stripe_public_key">{ t('app.admin.invoices.payment.public_key') } *</label>
          <FabInput id="stripe_public_key"
                    icon={<i className="fa fa-info" />}
                    value={publicKey}
                    onChange={testPublicKey}
                    addOn={publicKeyAddOn}
                    addOnClassName={publicKeyAddOnClassName}
                    debounce={200}
                    required />
        </div>
        <div className="stripe-secret-input">
          <label htmlFor="stripe_secret_key">{ t('app.admin.invoices.payment.secret_key') } *</label>
          <FabInput id="stripe_secret_key"
                    icon={<i className="fa fa-key" />}
                    value={secretKey}
                    onChange={testSecretKey}
                    addOn={secretKeyAddOn}
                    addOnClassName={secretKeyAddOnClassName}
                    debounce={200}
                    required/>
        </div>
      </form>
    </div>
  );
}

export const StripeKeysForm: React.FC<StripeKeysFormProps> = ({ onValidKeys }) => {
  return (
    <Loader>
      <StripeKeysFormComponent onValidKeys={onValidKeys} />
    </Loader>
  );
}

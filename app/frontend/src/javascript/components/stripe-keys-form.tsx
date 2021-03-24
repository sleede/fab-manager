/**
 * Form to set the stripe's public and private keys
 */

import React, { ReactNode, useEffect, useState } from 'react';
import { Loader } from './loader';
import { useTranslation } from 'react-i18next';
import SettingAPI from '../api/setting';
import { SettingName } from '../models/setting';
import { FabInput } from './fab-input';


interface StripeKeysFormProps {
  param: string
}

const stripeKeys = SettingAPI.query([SettingName.StripePublicKey, SettingName.StripeSecretKey]);

const StripeKeysFormComponent: React.FC<StripeKeysFormProps> = ({ param }) => {
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


  // see StripeKeysModalController
  // from app/frontend/src/javascript/controllers/admin/invoices.js

  const testPublicKey = () => {
    setPublicKeyAddOnClassName('key-valid');
    setPublicKeyAddOn(<i className="fa fa-check" />);
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
                    required />
          <div className="key-input">
            <span className="key-input__icon"><i className="fa fa-info" /></span>
            <input type="text"
                   id="stripe_public_key"
                   value={publicKey}
                   ng-model-options='{ debounce: 200 }'
                   ng-change='testPublicKey()'
                   required />
          <span className="input-group-addon"
                ng-class="{'label-success': publicKeyStatus, 'label-danger text-white': !publicKeyStatus}"
                ng-show="publicKeyStatus !== undefined && publicKey">
              <i className="fa fa-times" ng-show="!publicKeyStatus" />
              <i className="fa fa-check" ng-show="publicKeyStatus" />
            </span>
          </div>
        </div>
        <div className="stripe-secret-input">
          <label htmlFor="stripe_secret_key">{ t('app.admin.invoices.payment.secret_key') } *</label>
          <div className="key-input">
            <span className="key-input__icon"><i className="fa fa-key" /></span>
            <input type="text"
                   id="stripe_secret_key"
                   value={secretKey}
                   ng-model-options='{ debounce: 200 }'
                   ng-change='testSecretKey()'
                   required />
          <span className="input-group-addon"
                ng-class="{'label-success': secretKeyStatus, 'label-danger text-white': !secretKeyStatus}"
                ng-show="secretKeyStatus !== undefined && secretKey">
              <i className="fa fa-times" ng-show="!secretKeyStatus" />
              <i className="fa fa-check" ng-show="secretKeyStatus" />
            </span>
          </div>
        </div>
      </form>
    </div>
  );
}

export const StripeKeysForm: React.FC<StripeKeysFormProps> = ({ param }) => {
  return (
    <Loader>
      <StripeKeysFormComponent param={param} />
    </Loader>
  );
}

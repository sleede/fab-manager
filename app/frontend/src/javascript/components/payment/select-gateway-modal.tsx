/**
 * This component allows an administrator to select and configure a payment gateway.
 * The configuration of a payment gateway is required to enable the online payments.
 */

import { BaseSyntheticEvent, useEffect, useState } from 'react';

import * as React from 'react';
import { react2angular } from 'react2angular';
import { useTranslation } from 'react-i18next';
import { StripeKeysForm } from './stripe/stripe-keys-form';
import { PayzenKeysForm } from './payzen/payzen-keys-form';
import { FabModal, ModalSize } from '../base/fab-modal';
import { Loader } from '../base/loader';
import { User } from '../../models/user';
import { Gateway } from '../../models/gateway';
import { SettingBulkResult, SettingName } from '../../models/setting';
import { IApplication } from '../../models/application';
import SettingAPI from '../../api/setting';

declare const Application: IApplication;

interface SelectGatewayModalModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  currentUser: User,
  onError: (errors: string) => void,
  onSuccess: (results: Map<SettingName, SettingBulkResult>) => void,
}

/**
 * Modal dialog that enable an admin to configure the active payment gateway
 */
export const SelectGatewayModal: React.FC<SelectGatewayModalModalProps> = ({ isOpen, toggleModal, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [preventConfirmGateway, setPreventConfirmGateway] = useState<boolean>(true);
  const [selectedGateway, setSelectedGateway] = useState<string>('');
  const [gatewayConfig, setGatewayConfig] = useState<Map<SettingName, string>>(new Map());

  // request the configured gateway to the API
  useEffect(() => {
    SettingAPI.get('payment_gateway').then(gateway => {
      setSelectedGateway(gateway.value ? gateway.value : '');
    });
  }, []);

  /**
   * Callback triggered when the user has filled and confirmed the settings of his gateway
   */
  const onGatewayConfirmed = () => {
    setPreventConfirmGateway(true);
    updateSettings();
    setPreventConfirmGateway(false);
  };

  /**
   * Save the gateway provided by the target input into the component state
   */
  const setGateway = (event: BaseSyntheticEvent) => {
    const gateway = event.target.value;
    setSelectedGateway(gateway);
  };

  /**
   * Check if any payment gateway was selected
   */
  const hasSelectedGateway = (): boolean => {
    return selectedGateway !== '';
  };

  /**
   * Callback triggered when the embedded form has validated all the stripe keys
   */
  const handleValidStripeKeys = (publicKey: string, secretKey: string): void => {
    setGatewayConfig((prev) => {
      const newMap = new Map(prev);
      newMap.set('stripe_secret_key', secretKey);
      newMap.set('stripe_public_key', publicKey);
      return newMap;
    });
    setPreventConfirmGateway(false);
  };

  /**
   * Callback triggered when the embedded form has validated all the PayZen keys
   */
  const handleValidPayZenKeys = (payZenKeys: Map<SettingName, string>): void => {
    setGatewayConfig(payZenKeys);
    setPreventConfirmGateway(false);
  };

  /**
   * Callback triggered when the embedded form has not validated all keys
   */
  const handleInvalidKeys = (): void => {
    setPreventConfirmGateway(true);
  };

  /**
   * Send the new gateway settings to the API to save them
   */
  const updateSettings = (): void => {
    const settings = new Map<SettingName, string>(gatewayConfig);
    settings.set('payment_gateway', selectedGateway);

    SettingAPI.bulkUpdate(settings, true).then(result => {
      const errorResults = Array.from(result.values()).filter(item => !item.status);
      if (errorResults.length > 0) {
        onError(errorResults.map(item => item.error[0]).join(' '));
      } else {
        // we call the success callback only in case of full success (transactional bulk update)
        onSuccess(result);
      }
    }, reason => {
      onError(reason);
    });
  };

  return (
    <FabModal title={t('app.admin.invoices.payment.select_gateway_modal.select_gateway_title')}
      isOpen={isOpen}
      toggleModal={toggleModal}
      width={ModalSize.medium}
      className="select-gateway-modal"
      confirmButton={t('app.admin.invoices.payment.select_gateway_modal.confirm_button')}
      onConfirm={onGatewayConfirmed}
      preventConfirm={preventConfirmGateway}>
      {!hasSelectedGateway() && <p className="info-gateway">
        {t('app.admin.invoices.payment.select_gateway_modal.gateway_info')}
      </p>}
      <label htmlFor="gateway">{t('app.admin.invoices.payment.select_gateway_modal.select_gateway')}</label>
      <select id="gateway" className="select-gateway" onChange={setGateway} value={selectedGateway}>
        <option />
        <option value={Gateway.Stripe}>{t('app.admin.invoices.payment.select_gateway_modal.stripe')}</option>
        <option value={Gateway.PayZen}>{t('app.admin.invoices.payment.select_gateway_modal.payzen')}</option>
      </select>
      {selectedGateway === Gateway.Stripe && <StripeKeysForm onValidKeys={handleValidStripeKeys} onInvalidKeys={handleInvalidKeys} />}
      {selectedGateway === Gateway.PayZen && <PayzenKeysForm onValidKeys={handleValidPayZenKeys} onInvalidKeys={handleInvalidKeys} />}
    </FabModal>
  );
};

const SelectGatewayModalWrapper: React.FC<SelectGatewayModalModalProps> = (props) => {
  return (
    <Loader>
      <SelectGatewayModal {...props} />
    </Loader>
  );
};

Application.Components.component('selectGatewayModal', react2angular(SelectGatewayModalWrapper, ['isOpen', 'toggleModal', 'currentUser', 'onSuccess', 'onError']));

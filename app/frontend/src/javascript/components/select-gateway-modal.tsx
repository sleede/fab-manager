/**
 * This component allows an administrator to select and configure a payment gateway.
 * The configuration of a payment gateway is required to enable the online payments.
 */

import React, { BaseSyntheticEvent, useState } from 'react';
import { react2angular } from 'react2angular';
import { Loader } from './loader';
import { IApplication } from '../models/application';
import { useTranslation } from 'react-i18next';
import { FabModal, ModalSize } from './fab-modal';
import { User } from '../models/user';
import { Gateway } from '../models/gateway';
import { StripeKeysForm } from './stripe-keys-form';


declare var Application: IApplication;

interface SelectGatewayModalModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  currentUser: User,
}

const SelectGatewayModal: React.FC<SelectGatewayModalModalProps> = ({ isOpen, toggleModal }) => {
  const { t } = useTranslation('admin');

  const [preventConfirmGateway, setPreventConfirmGateway] = useState<boolean>(true);
  const [selectedGateway, setSelectedGateway] = useState<string>('');


  /**
   * Callback triggered when the user has filled and confirmed the settings of his gateway
   */
  const onGatewayConfirmed = () => {
    setPreventConfirmGateway(true);
    toggleModal();
  }

  /**
   * Save the gateway provided by the target input into the component state
   */
  const setGateway = (event: BaseSyntheticEvent) => {
    const gateway = event.target.value;
    setSelectedGateway(gateway);
    setPreventConfirmGateway(!gateway);
  }

  /**
   * Check if any payment gateway was selected
   */
  const hasSelectedGateway = (): boolean => {
    return selectedGateway !== '';
  }

  return (
    <FabModal title={t('app.admin.invoices.payment.gateway_modal.select_gateway_title')}
              isOpen={isOpen}
              toggleModal={toggleModal}
              width={ModalSize.medium}
              closeButton={false}
              className="gateway-modal"
              confirmButton={t('app.admin.invoices.payment.gateway_modal.confirm_button')}
              onConfirm={onGatewayConfirmed}
              preventConfirm={preventConfirmGateway}>
      {!hasSelectedGateway() && <p className="info-gateway">
        {t('app.admin.invoices.payment.gateway_modal.gateway_info')}
      </p>}
      <label htmlFor="gateway">{t('app.admin.invoices.payment.gateway_modal.select_gateway')}</label>
      <select id="gateway" className="select-gateway" onChange={setGateway} value={selectedGateway}>
        <option />
        <option value={Gateway.Stripe}>{t('app.admin.invoices.payment.gateway_modal.stripe')}</option>
        <option value={Gateway.PayZen}>{t('app.admin.invoices.payment.gateway_modal.payzen')}</option>
      </select>
      {selectedGateway === Gateway.Stripe && <StripeKeysForm param={'lorem ipsum'} />}
    </FabModal>
  );
};

const SelectGatewayModalWrapper: React.FC<SelectGatewayModalModalProps> = ({ isOpen, toggleModal, currentUser }) => {
  return (
    <Loader>
      <SelectGatewayModal isOpen={isOpen} toggleModal={toggleModal} currentUser={currentUser} />
    </Loader>
  );
}

Application.Components.component('selectGatewayModal', react2angular(SelectGatewayModalWrapper, ['isOpen', 'toggleModal', 'currentUser']));

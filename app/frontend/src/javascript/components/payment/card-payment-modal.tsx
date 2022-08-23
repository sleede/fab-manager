import React, { ReactElement, useEffect, useState } from 'react';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { StripeModal } from './stripe/stripe-modal';
import { PayzenModal } from './payzen/payzen-modal';
import { IApplication } from '../../models/application';
import { ShoppingCart } from '../../models/payment';
import { User } from '../../models/user';
import { PaymentSchedule } from '../../models/payment-schedule';
import { Setting } from '../../models/setting';
import { Invoice } from '../../models/invoice';
import SettingAPI from '../../api/setting';
import { useTranslation } from 'react-i18next';

declare const Application: IApplication;

interface CardPaymentModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: Invoice|PaymentSchedule) => void,
  onError: (message: string) => void,
  cart: ShoppingCart,
  currentUser: User,
  schedule?: PaymentSchedule,
  customer: User
}

/**
 * This component open a modal dialog for the configured payment gateway, allowing the user to input his card data
 * to process an online payment.
 */
const CardPaymentModal: React.FC<CardPaymentModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, currentUser, schedule, cart, customer }) => {
  const { t } = useTranslation('shared');

  const [gateway, setGateway] = useState<Setting>(null);

  useEffect(() => {
    SettingAPI.get('payment_gateway')
      .then(setting => setGateway(setting))
      .catch(error => onError(error));
  }, []);

  /**
   * Render the Stripe payment modal
   */
  const renderStripeModal = (): ReactElement => {
    return <StripeModal isOpen={isOpen}
      toggleModal={toggleModal}
      afterSuccess={afterSuccess}
      onError={onError}
      cart={cart}
      currentUser={currentUser}
      schedule={schedule}
      customer={customer} />;
  };

  /**
   * Render the PayZen payment modal
   */
  const renderPayZenModal = (): ReactElement => {
    return <PayzenModal isOpen={isOpen}
      toggleModal={toggleModal}
      afterSuccess={afterSuccess}
      onError={onError}
      cart={cart}
      currentUser={currentUser}
      schedule={schedule}
      customer={customer} />;
  };

  /**
   * Determine which gateway is enabled and return the appropriate payment modal
   */
  if (gateway === null || !isOpen) return <div/>;

  switch (gateway.value) {
    case 'stripe':
      return renderStripeModal();
    case 'payzen':
      return renderPayZenModal();
    case null:
    case undefined:
      onError(t('app.shared.card_payment_modal.online_payment_disabled'));
      return <div />;
    default:
      onError(t('app.shared.card_payment_modal.unexpected_error'));
      console.error(`[PaymentModal] Unimplemented gateway: ${gateway.value}`);
      return <div />;
  }
};

const CardPaymentModalWrapper: React.FC<CardPaymentModalProps> = (props) => {
  return (
    <Loader>
      <CardPaymentModal {...props} />
    </Loader>
  );
};

export { CardPaymentModalWrapper as CardPaymentModal };

Application.Components.component('cardPaymentModal', react2angular(CardPaymentModalWrapper, ['isOpen', 'toggleModal', 'afterSuccess', 'onError', 'currentUser', 'schedule', 'cart', 'customer']));

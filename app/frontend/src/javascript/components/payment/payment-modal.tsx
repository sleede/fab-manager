import React, { ReactElement } from 'react';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { StripeModal } from './stripe/stripe-modal';
import { PayZenModal } from './payzen/payzen-modal';
import { IApplication } from '../../models/application';
import { ShoppingCart } from '../../models/payment';
import { User } from '../../models/user';
import { PaymentSchedule } from '../../models/payment-schedule';
import { SettingName } from '../../models/setting';
import { Invoice } from '../../models/invoice';
import SettingAPI from '../../api/setting';
import { useTranslation } from 'react-i18next';

declare var Application: IApplication;

interface PaymentModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: Invoice|PaymentSchedule) => void,
  onError: (message: string) => void,
  cart: ShoppingCart,
  currentUser: User,
  schedule: PaymentSchedule,
  customer: User
}

// initial request to the API
const paymentGateway = SettingAPI.get(SettingName.PaymentGateway);

/**
 * This component open a modal dialog for the configured payment gateway, allowing the user to input his card data
 * to process an online payment.
 */
const PaymentModal: React.FC<PaymentModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, currentUser, schedule , cart, customer }) => {
  const { t } = useTranslation('shared');
  const gateway = paymentGateway.read();

  /**
   * Render the Stripe payment modal
   */
  const renderStripeModal = (): ReactElement => {
    return <StripeModal isOpen={isOpen}
                        toggleModal={toggleModal}
                        afterSuccess={afterSuccess}
                        cart={cart}
                        currentUser={currentUser}
                        schedule={schedule}
                        customer={customer} />
  }

  /**
   * Render the PayZen payment modal
   */
  const renderPayZenModal = (): ReactElement => {
    return <PayZenModal isOpen={isOpen}
                        toggleModal={toggleModal}
                        afterSuccess={afterSuccess}
                        cart={cart}
                        currentUser={currentUser}
                        schedule={schedule}
                        customer={customer} />
  }

  /**
   * Determine which gateway is enabled and return the appropriate payment modal
   */
  switch (gateway.value) {
    case 'stripe':
      return renderStripeModal();
    case 'payzen':
      return renderPayZenModal();
    case null:
    case undefined:
      onError(t('app.shared.payment_modal.online_payment_disabled'));
      return <div />;
    default:
      onError(t('app.shared.payment_modal.unexpected_error'));
      console.error(`[PaymentModal] Unimplemented gateway: ${gateway.value}`);
      return <div />;
  }
}


const PaymentModalWrapper: React.FC<PaymentModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, currentUser, schedule , cart, customer }) => {
  return (
    <Loader>
      <PaymentModal isOpen={isOpen} toggleModal={toggleModal} afterSuccess={afterSuccess} onError={onError} currentUser={currentUser} schedule={schedule} cart={cart} customer={customer} />
    </Loader>
  );
}

Application.Components.component('paymentModal', react2angular(PaymentModalWrapper, ['isOpen', 'toggleModal', 'afterSuccess', 'onError', 'currentUser', 'schedule', 'cart', 'customer']));

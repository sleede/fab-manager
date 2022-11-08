import React, { FunctionComponent, ReactNode } from 'react';
import { GatewayFormProps, AbstractPaymentModal } from '../abstract-payment-modal';
import { ShoppingCart } from '../../../models/payment';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { User } from '../../../models/user';
import { Invoice } from '../../../models/invoice';

import payzenLogo from '../../../../../images/payzen-secure.png';
import mastercardLogo from '../../../../../images/mastercard.png';
import visaLogo from '../../../../../images/visa.png';
import { PayzenForm } from './payzen-form';
import { Order } from '../../../models/order';

interface PayzenModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: Invoice|PaymentSchedule|Order) => void,
  onError: (message: string) => void,
  cart: ShoppingCart,
  order?: Order,
  currentUser: User,
  schedule?: PaymentSchedule,
  customer: User
}

/**
 * This component enables the user to input his card data or process payments, using the PayZen gateway.
 * Supports Strong-Customer Authentication (SCA).
 *
 * This component should not be called directly. Prefer using <CardPaymentModal> which can handle the configuration
 *  of a different payment gateway.
 */
export const PayzenModal: React.FC<PayzenModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, cart, currentUser, schedule, customer, order }) => {
  /**
   * Return the logos, shown in the modal footer.
   */
  const logoFooter = (): ReactNode => {
    return (
      <div className="payzen-modal-icons">
        <img src={payzenLogo} alt="powered by PayZen" />
        <img src={mastercardLogo} alt="mastercard" />
        <img src={visaLogo} alt="visa" />
      </div>
    );
  };

  /**
   * Integrates the PayzenForm into the parent PaymentModal
   */
  const renderForm: FunctionComponent<GatewayFormProps> = ({ onSubmit, onSuccess, onError, operator, className, formId, cart, customer, paymentSchedule, children, order }) => {
    return (
      <PayzenForm onSubmit={onSubmit}
        onSuccess={onSuccess}
        onError={onError}
        customer={customer}
        operator={operator}
        formId={formId}
        cart={cart}
        order={order}
        className={className}
        paymentSchedule={paymentSchedule}>
        {children}
      </PayzenForm>
    );
  };

  return (
    <AbstractPaymentModal isOpen={isOpen}
      toggleModal={toggleModal}
      logoFooter={logoFooter()}
      formId="payzen-form"
      formClassName="payzen-form"
      className="payzen-modal"
      currentUser={currentUser}
      cart={cart}
      order={order}
      customer={customer}
      afterSuccess={afterSuccess}
      onError={onError}
      schedule={schedule}
      GatewayForm={renderForm} />
  );
};

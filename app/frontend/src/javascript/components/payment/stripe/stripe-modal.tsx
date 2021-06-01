import React, { FunctionComponent, ReactNode } from 'react';
import { StripeElements } from './stripe-elements';
import { StripeForm } from './stripe-form';
import { GatewayFormProps, AbstractPaymentModal } from '../abstract-payment-modal';
import { ShoppingCart } from '../../../models/payment';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { User } from '../../../models/user';

import stripeLogo from '../../../../../images/powered_by_stripe.png';
import mastercardLogo from '../../../../../images/mastercard.png';
import visaLogo from '../../../../../images/visa.png';
import { Invoice } from '../../../models/invoice';


interface StripeModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: Invoice|PaymentSchedule) => void,
  cart: ShoppingCart,
  currentUser: User,
  schedule: PaymentSchedule,
  customer: User
}

/**
 * This component enables the user to input his card data or process payments, using the Stripe gateway.
 * Supports Strong-Customer Authentication (SCA).
 *
 * This component should not be called directly. Prefer using <PaymentModal> which can handle the configuration
 *  of a different payment gateway.
 */
export const StripeModal: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, cart, currentUser, schedule, customer }) => {
  /**
   * Return the logos, shown in the modal footer.
   */
  const logoFooter = (): ReactNode => {
    return (
      <div className="stripe-modal-icons">
        <i className="fa fa-lock fa-2x m-r-sm pos-rlt" />
        <img src={stripeLogo} alt="powered by stripe" />
        <img src={mastercardLogo} alt="mastercard" />
        <img src={visaLogo} alt="visa" />
      </div>
    );
  }

  /**
   * Integrates the StripeForm into the parent PaymentModal
   */
  const renderForm: FunctionComponent<GatewayFormProps> = ({ onSubmit, onSuccess, onError, operator, className, formId, cart, customer, paymentSchedule, children}) => {
    return (
      <StripeElements>
        <StripeForm onSubmit={onSubmit}
                    onSuccess={onSuccess}
                    onError={onError}
                    operator={operator}
                    className={className}
                    formId={formId}
                    cart={cart}
                    customer={customer}
                    paymentSchedule={paymentSchedule}>
          {children}
        </StripeForm>
      </StripeElements>
    );
  }

  return (
    <AbstractPaymentModal className="stripe-modal"
                          isOpen={isOpen}
                          toggleModal={toggleModal}
                          logoFooter={logoFooter()}
                          formId="stripe-form"
                          formClassName="stripe-form"
                          currentUser={currentUser}
                          cart={cart}
                          customer={customer}
                          afterSuccess={afterSuccess}
                          schedule={schedule}
                          GatewayForm={renderForm} />
  );
}

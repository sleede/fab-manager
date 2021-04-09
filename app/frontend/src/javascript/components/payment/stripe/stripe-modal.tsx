import React, { FunctionComponent, ReactNode } from 'react';
import { react2angular } from 'react2angular';
import { SetupIntent } from '@stripe/stripe-js';
import { StripeElements } from './stripe-elements';
import { StripeForm } from './stripe-form';
import { GatewayFormProps, AbstractPaymentModal } from '../abstract-payment-modal';
import { Loader } from '../../base/loader';
import { IApplication } from '../../../models/application';
import { CartItems, PaymentConfirmation } from '../../../models/payment';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { User } from '../../../models/user';

import stripeLogo from '../../../../../images/powered_by_stripe.png';
import mastercardLogo from '../../../../../images/mastercard.png';
import visaLogo from '../../../../../images/visa.png';

declare var Application: IApplication;

interface StripeModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: SetupIntent|PaymentConfirmation) => void,
  cartItems: CartItems,
  currentUser: User,
  schedule: PaymentSchedule,
  customer: User
}

/**
 * This component enables the user to input his card data or process payments, using the Stripe gateway.
 * Supports Strong-Customer Authentication (SCA).
 */
export const StripeModal: React.FC<StripeModalProps> = ({ isOpen, toggleModal, afterSuccess, cartItems, currentUser, schedule, customer }) => {
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
  const renderForm: FunctionComponent<GatewayFormProps> = ({ onSubmit, onSuccess, onError, operator, className, formId, cartItems, customer, paymentSchedule, children}) => {
    return (
      <StripeElements>
        <StripeForm onSubmit={onSubmit}
                    onSuccess={onSuccess}
                    onError={onError}
                    operator={operator}
                    className={className}
                    formId={formId}
                    cartItems={cartItems}
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
                          cartItems={cartItems}
                          customer={customer}
                          afterSuccess={afterSuccess}
                          schedule={schedule}
                          GatewayForm={renderForm} />
  );
}

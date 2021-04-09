import React, { FunctionComponent, ReactNode } from 'react';
import { react2angular } from 'react2angular';
import { Loader } from '../base/loader';
import { IApplication } from '../../models/application';
import { CartItems, PaymentConfirmation } from '../../models/payment';
import { PaymentSchedule } from '../../models/payment-schedule';
import { User } from '../../models/user';

import payzenLogo from '../../../../images/payzen-secure.png';
import mastercardLogo from '../../../../images/mastercard.png';
import visaLogo from '../../../../images/visa.png';
import { GatewayFormProps, AbstractPaymentModal } from '../payment/abstract-payment-modal';

declare var Application: IApplication;

interface PayZenModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: PaymentConfirmation) => void,
  cartItems: CartItems,
  currentUser: User,
  schedule: PaymentSchedule,
  customer: User
}

/**
 * This component enables the user to input his card data or process payments, using the PayZen gateway.
 * Supports Strong-Customer Authentication (SCA).
 */
const PayZenModal: React.FC<PayZenModalProps> = ({ isOpen, toggleModal, afterSuccess, cartItems, currentUser, schedule, customer }) => {
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
  }

  /**
   * Integrates the PayzenForm into the parent PaymentModal
   */
  const renderForm: FunctionComponent<GatewayFormProps> = ({ onSubmit, onSuccess, onError, operator, className, formId, cartItems, customer, paymentSchedule, children}) => {
    return (
      <form onSubmit={onSubmit} className={className} id={formId}>
        <h3>PayZen</h3>
        <input type="text" placeholder="card #"/>
        <span>Operated by {operator.name}</span>
        <span>User: {customer.name}</span>
        {children}
      </form>
    );
  }

  return (
    <AbstractPaymentModal isOpen={isOpen}
                          toggleModal={toggleModal}
                          logoFooter={logoFooter()}
                          formId="payzen-form"
                          formClassName="payzen-form"
                          className="payzen-modal"
                          currentUser={currentUser}
                          cartItems={cartItems}
                          customer={customer}
                          afterSuccess={afterSuccess}
                          schedule={schedule}
                          GatewayForm={renderForm} />
  );
}

const PayZenModalWrapper: React.FC<PayZenModalProps> = ({ isOpen, toggleModal, afterSuccess, currentUser, schedule , cartItems, customer }) => {
  return (
    <Loader>
      <PayZenModal isOpen={isOpen} toggleModal={toggleModal} afterSuccess={afterSuccess} currentUser={currentUser} schedule={schedule} cartItems={cartItems} customer={customer} />
    </Loader>
  );
}

Application.Components.component('payzenModal', react2angular(PayZenModalWrapper, ['isOpen', 'toggleModal', 'afterSuccess','currentUser', 'schedule', 'cartItems', 'customer']));

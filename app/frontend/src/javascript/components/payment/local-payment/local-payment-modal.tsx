import React, { FunctionComponent, ReactNode } from 'react';
import { AbstractPaymentModal, GatewayFormProps } from '../abstract-payment-modal';
import { LocalPaymentForm } from './local-payment-form';
import { ShoppingCart } from '../../../models/payment';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { User } from '../../../models/user';
import { Invoice } from '../../../models/invoice';
import { useTranslation } from 'react-i18next';
import { ModalSize } from '../../base/fab-modal';
import { Loader } from '../../base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../../../models/application';

declare const Application: IApplication;

interface LocalPaymentModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: Invoice|PaymentSchedule) => void,
  onError: (message: string) => void,
  cart: ShoppingCart,
  updateCart: (cart: ShoppingCart) => void,
  currentUser: User,
  schedule?: PaymentSchedule,
  customer: User
}

/**
 * This component enables a privileged user to confirm a local payments.
 */
const LocalPaymentModal: React.FC<LocalPaymentModalProps> = ({ isOpen, toggleModal, afterSuccess, onError, cart, updateCart, currentUser, schedule, customer }) => {
  const { t } = useTranslation('admin');

  /**
   * Return the logos, shown in the modal footer.
   */
  const logoFooter = (): ReactNode => {
    return (
      <div className="local-modal-icons">
        <i className="fas fa-lock fa-2x" />
      </div>
    );
  };

  /**
   * Generally, this modal dialog is only shown to admins or to managers when they book for someone else.
   * If this is not the case, then it is shown to validate a free (or prepaid by wallet) cart.
   * This function will return `true` in the later case.
   */
  const isFreeOfCharge = (): boolean => {
    return (customer.id === currentUser.id);
  };

  /**
   * Integrates the LocalPaymentForm into the parent AbstractPaymentModal
   */
  const renderForm: FunctionComponent<GatewayFormProps> = ({ onSubmit, onSuccess, onError, operator, className, formId, cart, updateCart, customer, paymentSchedule, children }) => {
    return (
      <LocalPaymentForm onSubmit={onSubmit}
        onSuccess={onSuccess}
        onError={onError}
        operator={operator}
        className={className}
        formId={formId}
        cart={cart}
        updateCart={updateCart}
        customer={customer}
        paymentSchedule={paymentSchedule}>
        {children}
      </LocalPaymentForm>
    );
  };

  return (
    <AbstractPaymentModal className="local-payment-modal"
      isOpen={isOpen}
      toggleModal={toggleModal}
      logoFooter={logoFooter()}
      title={isFreeOfCharge() ? t('app.admin.local_payment_modal.validate_cart') : t('app.admin.local_payment_modal.offline_payment')}
      formId="local-payment-form"
      formClassName="local-payment-form"
      currentUser={currentUser}
      cart={cart}
      updateCart={updateCart}
      customer={customer}
      afterSuccess={afterSuccess}
      onError={onError}
      schedule={schedule}
      GatewayForm={renderForm}
      modalSize={schedule ? ModalSize.large : ModalSize.medium}
      preventCgv
      preventScheduleInfo />
  );
};

const LocalPaymentModalWrapper: React.FC<LocalPaymentModalProps> = (props) => {
  return (
    <Loader>
      <LocalPaymentModal {...props} />
    </Loader>
  );
};

export { LocalPaymentModalWrapper as LocalPaymentModal };

Application.Components.component('localPaymentModal', react2angular(LocalPaymentModalWrapper, ['isOpen', 'toggleModal', 'afterSuccess', 'onError', 'currentUser', 'schedule', 'cart', 'updateCart', 'customer']));

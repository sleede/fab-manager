import React, { FunctionComponent, ReactNode } from 'react';
import { AbstractPaymentModal, GatewayFormProps } from '../abstract-payment-modal';
import { LocalPaymentForm } from './local-payment-form';
import { ShoppingCart } from '../../../models/payment';
import { PaymentSchedule } from '../../../models/payment-schedule';
import { User } from '../../../models/user';
import { Invoice } from '../../../models/invoice';
import { useTranslation } from 'react-i18next';
import { ModalSize } from '../../base/fab-modal';


interface LocalPaymentModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  afterSuccess: (result: Invoice|PaymentSchedule) => void,
  cart: ShoppingCart,
  currentUser: User,
  schedule?: PaymentSchedule,
  customer: User
}

/**
 * This component enables a privileged user to confirm a local payments.
 */
export const LocalPaymentModal: React.FC<LocalPaymentModalProps> = ({ isOpen, toggleModal, afterSuccess, cart, currentUser, schedule, customer }) => {

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
  }

  /**
   * Integrates the LocalPaymentForm into the parent AbstractPaymentModal
   */
  const renderForm: FunctionComponent<GatewayFormProps> = ({ onSubmit, onSuccess, onError, operator, className, formId, cart, customer, paymentSchedule, children}) => {
    return (
      <LocalPaymentForm onSubmit={onSubmit}
                        onSuccess={onSuccess}
                        onError={onError}
                        operator={operator}
                        className={className}
                        formId={formId}
                        cart={cart}
                        customer={customer}
                        paymentSchedule={paymentSchedule}>
        {children}
      </LocalPaymentForm>
    );
  }

  return (
    <AbstractPaymentModal className="local-payment-modal"
                          isOpen={isOpen}
                          toggleModal={toggleModal}
                          logoFooter={logoFooter()}
                          title={t('app.admin.local_payment.offline_payment')}
                          formId="local-payment-form"
                          formClassName="local-payment-form"
                          currentUser={currentUser}
                          cart={cart}
                          customer={customer}
                          afterSuccess={afterSuccess}
                          schedule={schedule}
                          GatewayForm={renderForm}
                          modalSize={schedule ? ModalSize.large : ModalSize.medium}
                          preventCgv />
  );
}

import React, { useEffect, useState } from 'react';
import { Subscription } from '../../models/subscription';
import { FabModal, ModalSize } from '../base/fab-modal';
import { useTranslation } from 'react-i18next';
import { FabAlert } from '../base/fab-alert';
import { FabInput } from '../base/fab-input';
import FormatLib from '../../lib/format';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import { PaymentMethod, ShoppingCart } from '../../models/payment';
import moment from 'moment';
import { SelectSchedule } from '../payment-schedule/select-schedule';
import SubscriptionAPI from '../../api/subscription';
import PriceAPI from '../../api/price';
import { ComputePriceResult } from '../../models/price';
import { PaymentScheduleSummary } from '../payment-schedule/payment-schedule-summary';
import { PaymentSchedule } from '../../models/payment-schedule';
import { LocalPaymentModal } from '../payment/local-payment/local-payment-modal';
import { User } from '../../models/user';
import { TDateISO } from '../../typings/date-iso';

declare const Application: IApplication;

interface RenewModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  subscription?: Subscription,
  customer: User,
  operator: User,
  onSuccess: (message: string, newExpirationDate: Date) => void,
  onError: (message: string) => void,
}

/**
 * Modal dialog shown to renew the current subscription of a customer, for free
 */
const RenewModal: React.FC<RenewModalProps> = ({ isOpen, toggleModal, subscription, customer, operator, onError, onSuccess }) => {
  // we do not render the modal if the subscription was not provided
  if (!subscription) return null;

  const { t } = useTranslation('admin');

  const [expirationDate, setExpirationDate] = useState<Date>(new Date());
  const [localPaymentModal, setLocalPaymentModal] = useState<boolean>(false);
  const [cart, setCart] = useState<ShoppingCart>(null);
  const [price, setPrice] = useState<ComputePriceResult>(null);
  const [scheduleRequired, setScheduleRequired] = useState<boolean>(false);

  // on init, we compute the new expiration date
  useEffect(() => {
    setExpirationDate(moment(subscription.expired_at)
      .add(subscription.plan.interval_count, subscription.plan.interval)
      .toDate());
    SubscriptionAPI.paymentsDetails(subscription.id)
      .then(res => setScheduleRequired(res.payment_schedule))
      .catch(err => onError(err));
  }, []);

  // when the payment schedule is toggled (requested/ignored), we update the cart accordingly
  useEffect(() => {
    setCart({
      customer_id: customer.id,
      items: [{
        subscription: {
          plan_id: subscription.plan.id,
          start_at: subscription.expired_at
        }
      }],
      payment_method: PaymentMethod.Other,
      payment_schedule: scheduleRequired
    });
  }, [scheduleRequired]);

  // when the cart is updated, re-compute the price and the payment schedule
  useEffect(() => {
    if (!cart) return;

    PriceAPI.compute(cart)
      .then(res => setPrice(res))
      .catch(err => onError(err));
  }, [cart]);

  /**
   * Return the formatted localized date for the given date
   */
  const formatDateTime = (date: Date|TDateISO): string => {
    return t('app.admin.free_extend_modal.DATE_TIME', { DATE: FormatLib.date(date), TIME: FormatLib.time(date) });
  };

  /**
   * Callback triggered when the payment of the subscription renewal was successful
   */
  const onPaymentSuccess = (): void => {
    onSuccess(t('app.admin.renew_subscription_modal.renew_success'), expirationDate);
    toggleModal();
  };

  /**
   * Open/closes the local payment modal
   */
  const toggleLocalPaymentModal = (): void => {
    setLocalPaymentModal(!localPaymentModal);
  };

  return (
    <FabModal isOpen={isOpen}
      toggleModal={toggleModal}
      width={ModalSize.large}
      className="renew-modal"
      title={t('app.admin.renew_subscription_modal.renew_subscription')}
      confirmButton={t('app.admin.renew_subscription_modal.renew')}
      onConfirm={toggleLocalPaymentModal}
      closeButton>
      <FabAlert level="danger" className="conditions">
        <p>{t('app.admin.renew_subscription_modal.renew_subscription_info')}</p>
        <p>{t('app.admin.renew_subscription_modal.credits_will_be_reset')}</p>
      </FabAlert>
      <div className="form-and-payment">
        <form className="configuration-form">
          <label htmlFor="current_expiration">{t('app.admin.renew_subscription_modal.current_expiration')}</label>
          <FabInput id="current_expiration"
            defaultValue={formatDateTime(subscription.expired_at)}
            readOnly />
          <label htmlFor="new_start">{t('app.admin.renew_subscription_modal.new_start')}</label>
          <FabInput id="new_start"
            defaultValue={formatDateTime(subscription.expired_at)}
            readOnly />
          <label htmlFor="new_expiration">{t('app.admin.renew_subscription_modal.new_expiration_date')}</label>
          <FabInput id="new_expiration"
            defaultValue={formatDateTime(expirationDate)}
            readOnly/>
        </form>
        <div className="payment">
          {subscription.plan.monthly_payment && <SelectSchedule show selected={scheduleRequired} onChange={setScheduleRequired} />}
          {price?.schedule && <PaymentScheduleSummary schedule={price.schedule as PaymentSchedule} />}
          {price && !price?.schedule && <div className="one-go-payment">
            <h4>{t('app.admin.renew_subscription_modal.pay_in_one_go')}</h4>
            <span>{FormatLib.price(price.price)}</span>
          </div>}
        </div>
      </div>
      <LocalPaymentModal isOpen={localPaymentModal}
        toggleModal={toggleLocalPaymentModal}
        afterSuccess={onPaymentSuccess}
        onError={onError}
        cart={cart}
        updateCart={setCart}
        currentUser={operator}
        customer={customer}
        schedule={price?.schedule as PaymentSchedule} />
    </FabModal>
  );
};

const RenewModalWrapper: React.FC<RenewModalProps> = ({ toggleModal, subscription, customer, operator, isOpen, onSuccess, onError }) => {
  return (
    <Loader>
      <RenewModal toggleModal={toggleModal} subscription={subscription} customer={customer} operator={operator} isOpen={isOpen} onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
};

Application.Components.component('renewModal', react2angular(RenewModalWrapper, ['toggleModal', 'subscription', 'customer', 'operator', 'isOpen', 'onError', 'onSuccess']));

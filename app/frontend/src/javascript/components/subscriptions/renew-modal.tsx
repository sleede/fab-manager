import React, { useEffect, useState } from 'react';
import { Subscription, SubscriptionPaymentDetails } from '../../models/subscription';
import { FabModal, ModalSize } from '../base/fab-modal';
import { useTranslation } from 'react-i18next';
import { FabAlert } from '../base/fab-alert';
import { FabInput } from '../base/fab-input';
import FormatLib from '../../lib/format';
import { Loader } from '../base/loader';
import { react2angular } from 'react2angular';
import { IApplication } from '../../models/application';
import LocalPaymentAPI from '../../api/local-payment';
import { PaymentMethod, ShoppingCart } from '../../models/payment';
import moment from 'moment';
import { SelectSchedule } from '../payment-schedule/select-schedule';
import SubscriptionAPI from '../../api/subscription';
import { PaymentScheduleSummary } from '../payment-schedule/payment-schedule-summary';

declare const Application: IApplication;

interface RenewModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  subscription?: Subscription,
  customerId: number,
  onSuccess: (message: string, newExpirationDate: Date) => void,
  onError: (message: string) => void,
}

/**
 * Modal dialog shown to renew the current subscription of a customer, for free
 */
const RenewModal: React.FC<RenewModalProps> = ({ isOpen, toggleModal, subscription, customerId, onError, onSuccess }) => {
  const { t } = useTranslation('admin');

  const [expirationDate, setExpirationDate] = useState<Date>(new Date());
  const [localPaymentModal, setLocalPaymentModal] = useState<boolean>(false);
  const [cart, setCart] = useState<ShoppingCart>(null);
  const [scheduleRequired, setScheduleRequired] = useState<boolean>(false);

  // on init, we compute the new expiration date
  useEffect(() => {
    if (!subscription) return;

    setExpirationDate(moment(subscription.expired_at)
      .add(subscription.plan.interval_count, subscription.plan.interval)
      .toDate());
    SubscriptionAPI.paymentsDetails(subscription.id)
      .then(res => setScheduleRequired(res.payment_schedule))
      .catch(err => onError(err));
  }, []);

  /**
   * Return the formatted localized date for the given date
   */
  const formatDateTime = (date: Date): string => {
    return t('app.admin.free_extend_modal.DATE_TIME', { DATE: FormatLib.date(date), TIME: FormatLib.time(date) });
  };

  /**
   * Callback triggered when the user validates the renew of the subscription
   */
  const handleConfirmRenew = (): void => {
    LocalPaymentAPI.confirmPayment({
      customer_id: customerId,
      payment_method: PaymentMethod.Other,
      items: [
        {
          subscription: {
            plan_id: subscription.plan_id
            // start_at: subscription.expired_at
          }
        }
      ]
    }).then(() => {
      onSuccess(t('app.admin.renew_subscription_modal.renew_success'), expirationDate);
      toggleModal();
    }).catch(err => onError(err));
  };

  // we do not render the modal if the subscription was not provided
  if (!subscription) return null;

  return (
    <FabModal isOpen={isOpen}
      toggleModal={toggleModal}
      width={ModalSize.large}
      className="renew-modal"
      title={t('app.admin.renew_subscription_modal.renew_subscription')}
      confirmButton={t('app.admin.renew_subscription_modal.renew')}
      onConfirm={handleConfirmRenew}
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
          <SelectSchedule show selected={scheduleRequired} onChange={setScheduleRequired} />
        </div>
      </div>
    </FabModal>
  );
};

const RenewModalWrapper: React.FC<RenewModalProps> = ({ toggleModal, subscription, customerId, isOpen, onSuccess, onError }) => {
  return (
    <Loader>
      <RenewModal toggleModal={toggleModal} subscription={subscription} customerId={customerId} isOpen={isOpen} onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
};

Application.Components.component('renewModal', react2angular(RenewModalWrapper, ['toggleModal', 'subscription', 'customerId', 'isOpen', 'onError', 'onSuccess']));

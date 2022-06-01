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
import LocalPaymentAPI from '../../api/local-payment';
import { PaymentMethod } from '../../models/payment';
import { TDateISO } from '../../typings/date-iso';

declare const Application: IApplication;

interface FreeExtendModalProps {
  isOpen: boolean,
  toggleModal: () => void,
  subscription: Subscription,
  customerId: number,
  onSuccess: (message: string, newExpirationDate: Date) => void,
  onError: (message: string) => void,
}

/**
 * Modal dialog shown to extend the current subscription of a customer, for free
 */
export const FreeExtendModal: React.FC<FreeExtendModalProps> = ({ isOpen, toggleModal, subscription, customerId, onError, onSuccess }) => {
  // we do not render the modal if the subscription was not provided
  if (!subscription) return null;

  const { t } = useTranslation('admin');

  const [expirationDate, setExpirationDate] = useState<Date>(new Date(subscription.expired_at));
  const [freeDays, setFreeDays] = useState<number>(0);

  // we update the number of free days when the new expiration date is updated
  useEffect(() => {
    if (!expirationDate || !subscription.expired_at) {
      setFreeDays(0);
    }
    // 86400000 = 1000 * 3600 * 24 = number of ms per day
    setFreeDays(Math.ceil((expirationDate.getTime() - new Date(subscription.expired_at).getTime()) / 86400000));
  }, [expirationDate]);

  /**
   * Return the formatted localized date for the given date
   */
  const formatDateTime = (date: TDateISO): string => {
    return t('app.admin.free_extend_modal.DATE_TIME', { DATE: FormatLib.date(date), TIME: FormatLib.time(date) });
  };

  /**
   * Return the given date formatted for the HTML input-date
   */
  const formatDefaultDate = (date: Date): string => {
    return date.toISOString().substr(0, 10);
  };

  /**
   * Parse the given date and record it as the new expiration date of the subscription
   */
  const handleDateUpdate = (date: string): void => {
    setExpirationDate(new Date(Date.parse(date)));
  };

  /**
   * Callback triggered when the user validates the free extent of the subscription
   */
  const handleConfirmExtend = (): void => {
    LocalPaymentAPI.confirmPayment({
      customer_id: customerId,
      payment_method: PaymentMethod.Other,
      items: [
        {
          free_extension: {
            end_at: expirationDate
          }
        }
      ]
    }).then(() => {
      onSuccess(t('app.admin.free_extend_modal.extend_success'), expirationDate);
      toggleModal();
    }).catch(err => onError(err));
  };

  return (
    <FabModal isOpen={isOpen}
      toggleModal={toggleModal}
      width={ModalSize.large}
      className="free-extend-modal"
      title={t('app.admin.free_extend_modal.extend_subscription')}
      confirmButton={t('app.admin.free_extend_modal.extend')}
      onConfirm={handleConfirmExtend}
      closeButton>
      <FabAlert level="danger" className="conditions">
        <p>{t('app.admin.free_extend_modal.offer_free_days_infos')}</p>
        <p>{t('app.admin.free_extend_modal.credits_will_remain_unchanged')}</p>
      </FabAlert>
      <form className="configuration-form">
        <label htmlFor="current_expiration">{t('app.admin.free_extend_modal.current_expiration')}</label>
        <FabInput id="current_expiration"
          defaultValue={formatDateTime(subscription.expired_at)}
          readOnly />
        <label htmlFor="new_expiration">{t('app.admin.free_extend_modal.new_expiration_date')}</label>
        <FabInput id="new_expiration"
          type="date"
          defaultValue={formatDefaultDate(expirationDate)}
          onChange={handleDateUpdate} />
        <label htmlFor="free_days">{t('app.admin.free_extend_modal.number_of_free_days')}</label>
        <input id="free_days" className="free-days" value={freeDays} readOnly />
      </form>
    </FabModal>
  );
};

const FreeExtendModalWrapper: React.FC<FreeExtendModalProps> = ({ toggleModal, subscription, customerId, isOpen, onSuccess, onError }) => {
  return (
    <Loader>
      <FreeExtendModal toggleModal={toggleModal} subscription={subscription} customerId={customerId} isOpen={isOpen} onError={onError} onSuccess={onSuccess} />
    </Loader>
  );
};

Application.Components.component('freeExtendModal', react2angular(FreeExtendModalWrapper, ['toggleModal', 'subscription', 'customerId', 'isOpen', 'onError', 'onSuccess']));

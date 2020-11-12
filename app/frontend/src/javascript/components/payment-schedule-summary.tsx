/**
 * This component displays a summary of the monthly payment schedule for the current cart, with a subscription
 */

import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import moment from 'moment';
import { IApplication } from '../models/application';
import '../lib/i18n';
import { IFilterService } from 'angular';
import { PaymentSchedule } from '../models/payment-schedule';
import { Loader } from './loader';
import { FabModal } from './fab-modal';

declare var Application: IApplication;

interface PaymentScheduleSummaryProps {
  schedule: PaymentSchedule,
  $filter: IFilterService
}

const PaymentScheduleSummary: React.FC<PaymentScheduleSummaryProps> = ({ schedule, $filter }) => {
  const { t } = useTranslation('shared');
  const [modal, setModal] = useState(false);

  /**
   * Return the formatted localized date for the given date
   */
  const formatDate = (date: Date): string => {
    return Intl.DateTimeFormat().format(moment(date).toDate());
  }
  /**
   * Return the formatted localized amount for the given price (eg. 20.5 => "20,50 €")
   */
  const formatPrice = (price: number): string => {
    return $filter('currency')(price);
  }
  /**
   * Test if all payment deadlines have the same amount
   */
  const hasEqualDeadlines = (): boolean => {
    const prices = schedule.items.map(i => i.amount);
    return prices.every(p => p === prices[0]);
  }
  /**
   * Open or closes the modal dialog showing the full payment schedule
   */
  const toggleFullScheduleModal = (): void => {
    setModal(!modal);
  }

  return (
    <div className="payment-schedule-summary">
      <div>
        <h4>{ t('app.shared.cart.your_payment_schedule') }</h4>
        {hasEqualDeadlines() && <ul>
          <li>
            <span className="schedule-item-info">
              {t('app.shared.cart.NUMBER_monthly_payment_of_AMOUNT', { NUMBER: schedule.items.length, AMOUNT: formatPrice(schedule.items[0].amount) })}
            </span>
            <span className="schedule-item-date">{t('app.shared.cart.first_debit')}</span>
          </li>
        </ul>}
        {!hasEqualDeadlines() && <ul>
          <li>
            <span className="schedule-item-info">{t('app.shared.cart.monthly_payment_NUMBER', { NUMBER: 1 })}</span>
            <span className="schedule-item-price">{formatPrice(schedule.items[0].amount)}</span>
            <span className="schedule-item-date">{t('app.shared.cart.debit')}</span>
          </li>
          <li>
            <span className="schedule-item-info">
              {t('app.shared.cart.NUMBER_monthly_payment_of_AMOUNT', { NUMBER: schedule.items.length - 1, AMOUNT: formatPrice(schedule.items[1].amount) })}
            </span>
          </li>
        </ul>}
        <button className="view-full-schedule" onClick={toggleFullScheduleModal}>{t('app.shared.cart.view_full_schedule')}</button>
        <FabModal title={t('app.shared.cart.your_payment_schedule')} isOpen={modal} toggleModal={toggleFullScheduleModal}>
          <ul className="full-schedule">
          {schedule.items.map(item => (
            <li key={String(item.due_date)}>
              <span className="schedule-item-date">{formatDate(item.due_date)}</span>
              <span> </span>
              <span className="schedule-item-price">{formatPrice(item.amount)}</span>
            </li>
          ))}
          </ul>
        </FabModal>
      </div>
    </div>
  );
}
const PaymentScheduleSummaryWrapper: React.FC<PaymentScheduleSummaryProps> = ({ schedule, $filter }) => {
  return (
    <Loader>
      <PaymentScheduleSummary schedule={schedule} $filter={$filter} />
      <div>lorem ipsum</div>
    </Loader>
  );
}

Application.Components.component('paymentScheduleSummary', react2angular(PaymentScheduleSummaryWrapper, ['schedule'], ['$filter']));

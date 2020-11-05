/**
 * This component displays a summary of the monthly payment schedule for the current cart, with a subscription
 */

import React, { useState, Suspense } from 'react';
import { useTranslation } from 'react-i18next';
import Modal from 'react-modal';
import { react2angular } from 'react2angular';
import moment from 'moment';
import { IApplication } from '../models/application';
import '../lib/i18n';
import { IFilterService } from 'angular';
import { PaymentSchedule } from '../models/payment-schedule';

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
    const prices = schedule.items.map(i => i.price);
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
        {hasEqualDeadlines() && <div>
          <span className="schedule-item-info">
            {t('app.shared.cart.NUMBER_monthly_payment_of_AMOUNT', { NUMBER: schedule.items.length, AMOUNT: formatPrice(schedule.items[0].price) })}
          </span>
          <span className="schedule-item-date">{t('app.shared.cart.first_debit')}</span>
        </div>}
        {!hasEqualDeadlines() && <ul>
          <li>
            <span className="schedule-item-info">{t('app.shared.cart.monthly_payment_NUMBER', { NUMBER: 1 })}</span>
            <span className="schedule-item-price">{formatPrice(schedule.items[0].price)}</span>
            <span className="schedule-item-date">{t('app.shared.cart.debit')}</span>
          </li>
          <li>
            <span className="schedule-item-info">
              {t('app.shared.cart.NUMBER_monthly_payment_of_AMOUNT', { NUMBER: schedule.items.length - 1, AMOUNT: formatPrice(schedule.items[1].price) })}
            </span>
          </li>
        </ul>}
        <a className="view-full-schedule" onClick={toggleFullScheduleModal}>{t('app.shared.cart.view_full_schedule')}</a>
        {/* TODO, create a component FabModal and put this inside */}
        <Modal isOpen={modal}
               className="full-schedule-modal"
               onRequestClose={toggleFullScheduleModal}>
          {schedule.items.map(item => (
            <li>
              <span className="schedule-item-date">{formatDate(item.due_date)}</span>
              <span> </span>
              <span className="schedule-item-price">{formatPrice(item.price)}</span>
            </li>
          ))}
        </Modal>
      </div>
    </div>
  );
}
const PaymentScheduleSummaryWrapper: React.FC<PaymentScheduleSummaryProps> = ({ schedule, $filter }) => {
  const loading = (
    <div className="fa-3x">
      <i className="fas fa-circle-notch fa-spin" />
    </div>
  );
  return (
    <Suspense fallback={loading}>
      <PaymentScheduleSummary schedule={schedule} $filter={$filter} />
    </Suspense>
  );
}

Application.Components.component('paymentScheduleSummary', react2angular(PaymentScheduleSummaryWrapper, ['schedule'], ['$filter']));

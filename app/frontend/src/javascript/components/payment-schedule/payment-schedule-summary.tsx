import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import '../../lib/i18n';
import { Loader } from '../base/loader';
import { FabModal } from '../base/fab-modal';
import { PaymentSchedule } from '../../models/payment-schedule';
import { IApplication } from '../../models/application';
import FormatLib from '../../lib/format';

declare var Application: IApplication;

interface PaymentScheduleSummaryProps {
  schedule: PaymentSchedule
}

/**
 * This component displays a summary of the monthly payment schedule for the current cart, with a subscription
 */
const PaymentScheduleSummary: React.FC<PaymentScheduleSummaryProps> = ({ schedule }) => {
  const { t } = useTranslation('shared');

  // is open, the modal dialog showing the full details of the payment schedule?
  const [modal, setModal] = useState(false);

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
              {t('app.shared.cart.NUMBER_monthly_payment_of_AMOUNT', { NUMBER: schedule.items.length, AMOUNT: FormatLib.price(schedule.items[0].amount) })}
            </span>
            <span className="schedule-item-date">{t('app.shared.cart.first_debit')}</span>
          </li>
        </ul>}
        {!hasEqualDeadlines() && <ul>
          <li>
            <span className="schedule-item-info">{t('app.shared.cart.monthly_payment_NUMBER', { NUMBER: 1 })}</span>
            <span className="schedule-item-price">{FormatLib.price(schedule.items[0].amount)}</span>
            <span className="schedule-item-date">{t('app.shared.cart.debit')}</span>
          </li>
          <li>
            <span className="schedule-item-info">
              {t('app.shared.cart.NUMBER_monthly_payment_of_AMOUNT', { NUMBER: schedule.items.length - 1, AMOUNT: FormatLib.price(schedule.items[1].amount) })}
            </span>
          </li>
        </ul>}
        <button className="view-full-schedule" onClick={toggleFullScheduleModal}>{t('app.shared.cart.view_full_schedule')}</button>
        <FabModal title={t('app.shared.cart.your_payment_schedule')} isOpen={modal} toggleModal={toggleFullScheduleModal}>
          <ul className="full-schedule">
          {schedule.items.map(item => (
            <li key={String(item.due_date)}>
              <span className="schedule-item-date">{FormatLib.date(item.due_date)}</span>
              <span> </span>
              <span className="schedule-item-price">{FormatLib.price(item.amount)}</span>
            </li>
          ))}
          </ul>
        </FabModal>
      </div>
    </div>
  );
}
const PaymentScheduleSummaryWrapper: React.FC<PaymentScheduleSummaryProps> = ({ schedule }) => {
  return (
    <Loader>
      <PaymentScheduleSummary schedule={schedule} />
    </Loader>
  );
}

Application.Components.component('paymentScheduleSummary', react2angular(PaymentScheduleSummaryWrapper, ['schedule']));

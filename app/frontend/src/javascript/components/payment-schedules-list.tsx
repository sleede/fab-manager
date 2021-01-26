/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */

import React, { useState } from 'react';
import { IApplication } from '../models/application';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import { react2angular } from 'react2angular';
import PaymentScheduleAPI from '../api/payment-schedule';
import { LabelledInput } from './labelled-input';

declare var Application: IApplication;

const paymentSchedulesList = PaymentScheduleAPI.list({ query: { page: 1, size: 20 } });

const PaymentSchedulesList: React.FC = () => {
  const { t } = useTranslation('admin');
  const [referenceFilter, setReferenceFilter] = useState('');
  const [customerFilter, setCustomerFilter] = useState('');
  const [dateFilter, setDateFilter] = useState(null);

  const paymentSchedules = paymentSchedulesList.read();

  return (
    <div className="payment-schedules-list">
      <h3>
        <i className="fas fa-filter" />
        {t('app.admin.invoices.payment_schedules.filter_schedules')}
      </h3>
      <div className="schedules-filters">
        <LabelledInput id="reference"
                       label={t('app.admin.invoices.payment_schedules.reference')}
                       type="text"
                       onChange={setReferenceFilter}
                       value={referenceFilter} />
        <LabelledInput id="customer"
                       label={t('app.admin.invoices.payment_schedules.customer')}
                       type="text"
                       onChange={setCustomerFilter}
                       value={customerFilter} />
        <LabelledInput id="reference"
                       label={t('app.admin.invoices.payment_schedules.date')}
                       type="date"
                       onChange={setDateFilter}
                       value={dateFilter} />
      </div>
      <ul>
        {paymentSchedules.map(p => <li>{p.reference}</li>)}
      </ul>
    </div>
  );
}


const PaymentSchedulesListWrapper: React.FC = () => {
  return (
    <Loader>
      <PaymentSchedulesList />
    </Loader>
  );
}

Application.Components.component('paymentSchedulesList', react2angular(PaymentSchedulesListWrapper));

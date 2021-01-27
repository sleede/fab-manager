/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */

import React, { useState } from 'react';
import { IApplication } from '../models/application';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import { react2angular } from 'react2angular';
import PaymentScheduleAPI from '../api/payment-schedule';
import { DocumentFilters } from './document-filters';
import { PaymentSchedulesTable } from './payment-schedules-table';

declare var Application: IApplication;

const paymentSchedulesList = PaymentScheduleAPI.list({ query: { page: 1, size: 20 } });

const PaymentSchedulesList: React.FC = () => {
  const { t } = useTranslation('admin');

  const [paymentSchedules, setPaymentSchedules] = useState(paymentSchedulesList.read());

  const handleFiltersChange = ({ reference, customer, date }): void => {
    const api = new PaymentScheduleAPI();
    api.list({ query: { reference, customer, date, page: 1, size: 20 }}).then((res) => {
      setPaymentSchedules(res);
    });
  };

  return (
    <div className="payment-schedules-list">
      <h3>
        <i className="fas fa-filter" />
        {t('app.admin.invoices.payment_schedules.filter_schedules')}
      </h3>
      <div className="schedules-filters">
        <DocumentFilters onFilterChange={handleFiltersChange} />
      </div>
      <PaymentSchedulesTable paymentSchedules={paymentSchedules} showCustomer={true} />
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

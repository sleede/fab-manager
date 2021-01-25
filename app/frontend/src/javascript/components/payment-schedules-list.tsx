/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */

import React, { useState } from 'react';
import { IApplication } from '../models/application';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import { react2angular } from 'react2angular';
import PaymentScheduleAPI from '../api/payment-schedule';

declare var Application: IApplication;

const paymentSchedulesList = PaymentScheduleAPI.list({ query: { page: 1, size: 20 } });

const PaymentSchedulesList: React.FC = () => {
  const { t } = useTranslation('admin');

  const paymentSchedules = paymentSchedulesList.read();

  return (
    <div className="payment-schedules-list">
      <ul>
      {paymentSchedules.map(p => `<li>${p.reference}</li>`)}
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

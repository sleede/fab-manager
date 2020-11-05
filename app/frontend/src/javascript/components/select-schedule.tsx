/**
 * This component is a switch enabling the users to choose if they want to pay by monthly schedule
 * or with a one time payment
 */

import React, { Suspense } from 'react';
import { useTranslation } from 'react-i18next';
import { react2angular } from 'react2angular';
import Switch from 'react-switch';
import { IApplication } from '../models/application';
import '../lib/i18n';

declare var Application: IApplication;

interface SelectScheduleProps {
  show: boolean,
  selected: boolean,
  onChange: (selected: boolean) => void,
  className: string,
}

const SelectSchedule: React.FC<SelectScheduleProps> = ({ show, selected, onChange, className }) => {
  const { t } = useTranslation('shared');

  return (
    <div className="select-schedule">
      {show && <div className={className}>
        <label htmlFor="payment_schedule">{ t('app.shared.cart.monthly_payment') }</label>
        <Switch checked={selected} id="payment_schedule" onChange={onChange} className="schedule-switch"></Switch>
      </div>}
    </div>
  );
}

const SelectScheduleWrapper: React.FC<SelectScheduleProps> = ({ show, selected, onChange, className }) => {
  const loading = (
    <div className="fa-3x">
      <i className="fas fa-circle-notch fa-spin" />
    </div>
  );
  return (
    <Suspense fallback={loading}>
      <SelectSchedule show={show} selected={selected} onChange={onChange} className={className} />
    </Suspense>
  );
}

Application.Components.component('selectSchedule', react2angular(SelectScheduleWrapper, ['show', 'selected', 'onChange', 'className']));

/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */

import React, { ReactEventHandler, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import moment from 'moment';
import { IFablab } from '../models/fablab';
import _ from 'lodash';
import { PaymentSchedule, PaymentScheduleItem, PaymentScheduleItemState } from '../models/payment-schedule';

declare var Fablab: IFablab;

interface PaymentSchedulesTableProps {
  paymentSchedules: Array<PaymentSchedule>,
  showCustomer?: boolean
}

const PaymentSchedulesTableComponent: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer }) => {
  const { t } = useTranslation('admin');

  const [showExpanded, setShowExpanded] = useState({});

  const isExpanded = (paymentScheduleId: number): boolean => {
    return showExpanded[paymentScheduleId];
  }

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
    return new Intl.NumberFormat(Fablab.intl_locale, {style: 'currency', currency: Fablab.intl_currency}).format(price);
  }

  const statusDisplay = (paymentScheduleId: number): string => {
    if (isExpanded(paymentScheduleId)) {
      return 'table-row'
    } else {
      return 'none';
    }
  }

  const expandCollapseIcon = (paymentScheduleId: number): JSX.Element => {
    if (isExpanded(paymentScheduleId)) {
      return <i className="fas fa-minus-square" />;
    } else {
      return <i className="fas fa-plus-square" />
    }
  }

  const togglePaymentScheduleDetails = (paymentScheduleId: number): ReactEventHandler => {
    return (): void => {
      if (isExpanded(paymentScheduleId)) {
        setShowExpanded(Object.assign({}, showExpanded, { [paymentScheduleId]: false }));
      } else {
        setShowExpanded(Object.assign({}, showExpanded, { [paymentScheduleId]: true }));
      }
    }
  }

  enum TargetType {
    Invoice = 'invoices',
    PaymentSchedule = 'payment_schedules'
  }
  const downloadButton = (target: TargetType, id: number): JSX.Element => {
    const link = `api/${target}/${id}/download`;
    return (
      <a href={link} target="_blank" className="download-button">
        <i className="fas fa-download" />
        {t('app.admin.invoices.schedules_table.download')}
      </a>
    );
  }

  const formatState = (item: PaymentScheduleItem): JSX.Element => {
    let res = t(`app.admin.invoices.schedules_table.state_${item.state}`);
    if (item.state === PaymentScheduleItemState.Paid) {
      res += ` (${item.payment_method})`;
    }
    return <span className={`state-${item.state}`}>{res}</span>;
  }

  const itemButtons = (item: PaymentScheduleItem): JSX.Element => {
    switch (item.state) {
      case PaymentScheduleItemState.Paid:
        return downloadButton(TargetType.Invoice, item.invoice_id);
      case PaymentScheduleItemState.Pending:
        return (<span><button>encaisser le chèque</button><button>réessayer (stripe)</button></span>);
      default:
        return <span />
    }
  }

  return (
    <table className="schedules-table">
      <thead>
      <tr>
        <th className="w-35" />
        <th className="w-200">{t('app.admin.invoices.schedules_table.schedule_num')}</th>
        <th className="w-200">{t('app.admin.invoices.schedules_table.date')}</th>
        <th className="w-120">{t('app.admin.invoices.schedules_table.price')}</th>
        {showCustomer && <th className="w-200">{t('app.admin.invoices.schedules_table.customer')}</th>}
        <th className="w-200"/>
      </tr>
      </thead>
      <tbody>
      {paymentSchedules.map(p => <tr key={p.id}>
        <td colSpan={6}>
          <table className="schedules-table-body">
            <tbody>
            <tr>
              <td className="w-35 row-header" onClick={togglePaymentScheduleDetails(p.id)}>{expandCollapseIcon(p.id)}</td>
              <td className="w-200">{p.reference}</td>
              <td className="w-200">{formatDate(p.created_at)}</td>
              <td className="w-120">{formatPrice(p.total)}</td>
              {showCustomer && <td className="w-200">{p.user.name}</td>}
              <td className="w-200">{downloadButton(TargetType.PaymentSchedule, p.id)}</td>
            </tr>
            <tr style={{ display: statusDisplay(p.id) }}>
              <td className="w-35" />
              <td colSpan={5}>
                <div>
                  <table className="schedule-items-table">
                    <thead>
                    <tr>
                      <th className="w-120">{t('app.admin.invoices.schedules_table.deadline')}</th>
                      <th className="w-120">{t('app.admin.invoices.schedules_table.amount')}</th>
                      <th className="w-200">{t('app.admin.invoices.schedules_table.state')}</th>
                      <th className="w-200" />
                    </tr>
                    </thead>
                    <tbody>
                    {_.orderBy(p.items, 'due_date').map(item => <tr key={item.id}>
                      <td>{formatDate(item.due_date)}</td>
                      <td>{formatPrice(item.amount)}</td>
                      <td>{formatState(item)}</td>
                      <td>{itemButtons(item)}</td>
                    </tr>)}
                    </tbody>
                  </table>
                </div>
              </td>
            </tr>
            </tbody>
          </table>
        </td>
      </tr>)}
      </tbody>
    </table>
  );
};
PaymentSchedulesTableComponent.defaultProps = { showCustomer: false };


export const PaymentSchedulesTable: React.FC<PaymentSchedulesTableProps> = ({ paymentSchedules, showCustomer }) => {
  return (
    <Loader>
      <PaymentSchedulesTableComponent paymentSchedules={paymentSchedules} showCustomer={showCustomer} />
    </Loader>
  );
}

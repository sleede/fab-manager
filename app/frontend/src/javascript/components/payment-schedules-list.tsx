/**
 * This component shows a list of all payment schedules with their associated deadlines (aka. PaymentScheduleItem) and invoices
 */

import React, { ReactEventHandler, useState } from 'react';
import { IApplication } from '../models/application';
import { useTranslation } from 'react-i18next';
import { Loader } from './loader';
import { react2angular } from 'react2angular';
import PaymentScheduleAPI from '../api/payment-schedule';
import { DocumentFilters } from './document-filters';
import moment from 'moment';
import { IFablab } from '../models/fablab';
import _ from 'lodash';

declare var Application: IApplication;
declare var Fablab: IFablab;

const paymentSchedulesList = PaymentScheduleAPI.list({ query: { page: 1, size: 20 } });

const PaymentSchedulesList: React.FC = () => {
  const { t } = useTranslation('admin');

  const [paymentSchedules, setPaymentSchedules] = useState(paymentSchedulesList.read());
  const [showExpanded, setShowExpanded] = useState({});

  const handleFiltersChange = ({ reference, customer, date }): void => {
    const api = new PaymentScheduleAPI();
    api.list({ query: { reference, customer, date, page: 1, size: 20 }}).then((res) => {
      setPaymentSchedules(res);
    });
  };

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

  return (
    <div className="payment-schedules-list">
      <h3>
        <i className="fas fa-filter" />
        {t('app.admin.invoices.payment_schedules.filter_schedules')}
      </h3>
      <div className="schedules-filters">
        <DocumentFilters onFilterChange={handleFiltersChange} />
      </div>
      <table className="schedules-table">
        <thead>
          <tr>
            <th className="w-35" />
            <th className="w-200">Échéancier n°</th>
            <th className="w-200">Date</th>
            <th className="w-120">Prix</th>
            <th className="w-200">Client</th>
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
                  <td className="w-200">{p.user.name}</td>
                  <td className="w-200"><button>Télécharger</button></td>
                </tr>
                <tr style={{ display: statusDisplay(p.id) }}>
                  <td className="w-35" />
                  <td colSpan={5}>
                    <div>
                      <table className="schedule-items-table">
                        <thead>
                        <tr>
                          <th className="w-120">Échéance</th>
                          <th className="w-120">Montant</th>
                          <th className="w-200">État</th>
                          <th className="w-200" />
                        </tr>
                        </thead>
                        <tbody>
                          {_.orderBy(p.items, 'due_date').map(item => <tr key={item.id}>
                            <td>{formatDate(item.due_date)}</td>
                            <td>{formatPrice(item.amount)}</td>
                            <td>{item.state} {item.state === 'paid' ? `(${item.payment_method})` : ''}</td>
                            <td>{item.state === 'paid' ? <button>Télécharger</button> : ''}</td>
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
      <ul>

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
